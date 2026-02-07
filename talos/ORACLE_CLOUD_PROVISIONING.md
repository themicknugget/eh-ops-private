# Oracle Cloud Talos Node Provisioning Guide

This document describes the proper process for adding a new Talos Linux worker node on Oracle Cloud Infrastructure (OCI) that connects to a remote cluster via Tailscale.

## Overview

Oracle Cloud ARM64 instances (Ampere A1) require a specific provisioning workflow because:
1. Disk images are flashed directly via `dd` (skips the Talos install phase)
2. System extensions are only activated during install/upgrade phases
3. Remote connectivity via Tailscale requires the extension to be activated
4. Worker nodes need control plane access to get certificates

## Prerequisites

- Tailscale subnet router configured to advertise control plane IPs
- Oracle Cloud instance created with sufficient disk space
- Factory Talos image with required extensions (tailscale)
- SOPS age key for decrypting secrets

## Provisioning Steps

### 1. Prepare the Factory Image

Get the raw disk image URL for Oracle Cloud ARM64:

```bash
SCHEMATIC_ID="4a0d65c669d46663f377e7161e50cfd570c401f26fd9e7bda34a0216b6f1922b"
TALOS_VERSION="v1.12.2"
IMAGE_URL="https://factory.talos.dev/image/${SCHEMATIC_ID}/${TALOS_VERSION}/oracle-arm64.raw.xz"
```

This schematic includes:
- `siderolabs/tailscale` (required for remote connectivity)

**Note:** `qemu-guest-agent` is excluded because Oracle Cloud doesn't expose the virtio-serial device needed for it to function.

### 2. Flash the Disk Image

Boot the instance into rescue mode and flash the image:

```bash
# Download and write directly to disk
curl -L "${IMAGE_URL}" | xzcat | dd of=/dev/sda bs=4M status=progress conv=fsync
```

**Important:** This skips the install phase, so extensions are NOT activated yet.

### 3. Configure Node in talconfig.yaml

Add the node configuration with proper settings for Oracle Cloud:

```yaml
- hostname: cloudbox2
  ipAddress: 10.0.0.214  # Oracle Cloud internal IP
  controlPlane: false
  installDisk: /dev/sda
  talosImageURL: factory.talos.dev/oracle-installer/${SCHEMATIC_ID}
  machineSpec:
    mode: cloud
    secureboot: false
  certSANs:
    - 150.136.211.213  # Public IP
    - 10.0.0.214       # Internal IP
  extensionServices:
    - name: tailscale
      environment:
        - TS_AUTHKEY=${tailscaleAuthKey}
        - TS_EXTRA_ARGS=--accept-routes  # Accept subnet routes
  patches:
    - |-
      apiVersion: v1alpha1
      kind: ResolverConfig
      nameservers:
        - address: 169.254.169.254  # Oracle Cloud metadata DNS
    - |-
      machine:
        network:
          kubespan:
            enabled: false  # Using Tailscale instead
        kubelet:
          nodeIP:
            validSubnets:
              - 10.0.0.0/24  # Ensure correct IP selection
      cluster:
        controlPlane:
          endpoint: https://192.168.1.50:6443  # Unified control plane LB
  networkInterfaces:
    - deviceSelector:
        hardwareAddr: 02:00:17:27:16:32  # Get from Oracle Cloud console
      dhcp: false
      addresses:
        - 10.0.0.214/24
      routes:
        - network: 0.0.0.0/0
          gateway: 10.0.0.1
        - network: 169.254.0.0/16  # Required for Oracle Cloud metadata
```

### 4. Create Temporary Bootstrap Configuration

Generate a temporary single-node control plane config:

```bash
cd /tmp
talosctl gen config temp-cluster https://127.0.0.1:6443 \
  --install-disk /dev/sda \
  --install-image factory.talos.dev/installer/${SCHEMATIC_ID}:${TALOS_VERSION} \
  --additional-sans cloudbox2-temp \
  --additional-sans <PUBLIC_IP>
```

This creates:
- `/tmp/controlplane.yaml` - Temporary config
- `/tmp/talosconfig` - Temporary talosconfig for access

### 5. Apply Temporary Config and Bootstrap

Reboot the instance normally and apply the temporary config:

```bash
# Wait for instance to boot
talosctl -n <PUBLIC_IP> apply-config --file /tmp/controlplane.yaml --insecure

# Wait for node to come up
sleep 30

# Bootstrap the temporary single-node cluster
talosctl --talosconfig /tmp/talosconfig -e <PUBLIC_IP> -n cloudbox2-temp bootstrap
```

**Why this works:**
- Node boots as a self-contained control plane
- No external dependencies needed
- Talos API becomes available for upgrade

### 6. Upgrade to Activate Extensions

Run the upgrade to activate system extensions:

```bash
talosctl --talosconfig /tmp/talosconfig \
  -e <PUBLIC_IP> -n cloudbox2-temp \
  upgrade --image factory.talos.dev/installer/${SCHEMATIC_ID}:${TALOS_VERSION} \
  --preserve --wait=false
```

**This is the critical step** - the upgrade installs and activates the Tailscale extension.

Wait for the upgrade to complete (node will reboot):

```bash
# Wait for reboot
sleep 60

# Verify extensions are active
talosctl --talosconfig /tmp/talosconfig \
  -e <PUBLIC_IP> -n cloudbox2-temp \
  get extensions
```

Expected output:
```
NAME               VERSION
qemu-guest-agent   10.2.0
tailscale          1.92.3
schematic          <schematic-id>
```

### 7. Apply Real Worker Configuration

Generate the real cluster configs:

```bash
cd /workspace/eh-ops-private/talos
SOPS_AGE_KEY_FILE=/workspace/.age.key talhelper genconfig
```

Apply the real worker config to join the actual cluster:

```bash
talosctl --talosconfig /tmp/talosconfig \
  -e <PUBLIC_IP> -n cloudbox2-temp \
  apply-config --file clusterconfig/eh-ops-cloudbox2.yaml
```

The node will reboot and:
- Switch from control plane to worker mode
- Connect to Tailscale
- Reach the real control plane at 192.168.1.50
- Get certificates from trustd
- Join the cluster

### 8. Verify Node Joined

Check the node status:

```bash
# Wait for node to stabilize
sleep 60

# Check with actual cluster talosconfig
talosctl --talosconfig clusterconfig/talosconfig \
  -n <PUBLIC_IP> get services

# Verify in Kubernetes
kubectl get nodes
```

Expected output:
```
NAME        STATUS   ROLES    AGE   VERSION
cloudbox2   Ready    <none>   5m    v1.35.0
```

## Troubleshooting

### Tailscale Not Starting

Check service status:
```bash
talosctl -n <PUBLIC_IP> service ext-tailscale
```

Common issues:
- Auth key expired - generate new key in Tailscale admin console
- Tag permissions - remove `--advertise-tags` if not configured in ACLs

### apid Not Starting

Check for certificate signing errors:
```bash
talosctl -n <PUBLIC_IP> dmesg | grep "controller failed.*trustd"
```

Common issues:
- No route to control plane - verify Tailscale subnet routes
- Trustd unreachable - check control plane LB is at 192.168.1.50:50001

### Node NotReady in Kubernetes

Check Cilium status:
```bash
kubectl describe node cloudbox2 | grep -A 10 "Conditions:"
```

Wait for Cilium to configure networking (usually 30-60 seconds).

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Oracle Cloud (10.0.0.0/24)                                  │
│                                                              │
│  ┌─────────────────────────────────────────┐               │
│  │ cloudbox2                                │               │
│  │ - Internal IP: 10.0.0.214                │               │
│  │ - Public IP: 150.136.211.213             │               │
│  │ - Tailscale IP: 100.122.85.120           │               │
│  │                                           │               │
│  │ ┌─────────────────────────────────────┐ │               │
│  │ │ Tailscale                           │ │               │
│  │ │ - Accept routes: 192.168.1.51-53    │ │               │
│  │ │ - Accept routes: 192.168.1.50       │ │               │
│  │ └─────────────────────────────────────┘ │               │
│  └─────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Tailscale VPN
                         │
┌─────────────────────────────────────────────────────────────┐
│ Home Network (192.168.1.0/24)                               │
│                                                              │
│  ┌─────────────────────────────────────────────┐           │
│  │ Control Plane LB: 192.168.1.50              │           │
│  │ - Port 6443: Kubernetes API                  │           │
│  │ - Port 50000: Talos API (apid)              │           │
│  │ - Port 50001: trustd (certificates)         │           │
│  │                                               │           │
│  │ Backends:                                     │           │
│  │ - 192.168.1.51 (mini1)                       │           │
│  │ - 192.168.1.52 (mini2)                       │           │
│  │ - 192.168.1.53 (mini3)                       │           │
│  └─────────────────────────────────────────────┘           │
│                                                              │
│  ┌─────────────────────────────────────────────┐           │
│  │ eh-ops-subnet (Tailscale Router)            │           │
│  │ - Advertises: 192.168.1.50/32               │           │
│  │ - Advertises: 192.168.1.51-53/32            │           │
│  └─────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Oracle Cloud Specifics

### Metadata Service (IMDS)

Oracle Cloud's metadata service is essential for cloud-init and DNS:
- **Endpoint:** 169.254.169.254
- **DNS:** 169.254.169.254:53
- **Route Required:** 169.254.0.0/16 (link-local)

This is configured in the ResolverConfig and routes sections.

### Guest Agents

Neither QEMU guest agent nor Oracle Cloud Agent work on Talos:
- **QEMU guest agent:** No virtio-serial device exposed by OCI
- **Oracle Cloud Agent:** Requires systemd + snapd (incompatible with Talos)

Use agentless monitoring from OCI console instead.

### Network Configuration

Oracle Cloud requires:
- Static IP configuration (DHCP not recommended for Kubernetes nodes)
- Link-local route for metadata service
- Correct MAC address in deviceSelector

## Important Notes

1. **Extensions must be activated via upgrade** - Simply having them in the image isn't enough
2. **Control plane endpoint must be reachable** - Ensure Tailscale subnet routes are configured
3. **Temporary config is necessary** - Direct worker config won't work without activated extensions
4. **Bootstrap is required** - The temporary cluster must be bootstrapped to access the upgrade API
5. **Public IP in certSANs** - Required for talosctl access during provisioning

## Related Documentation

- [Talos Oracle Cloud Guide](https://www.talos.dev/v1.12/talos-guides/install/cloud-platforms/oracle/)
- [Talos System Extensions](https://www.talos.dev/v1.12/talos-guides/configuration/system-extensions/)
- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets)
- [Oracle Cloud IMDS](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/gettingmetadata.htm)
