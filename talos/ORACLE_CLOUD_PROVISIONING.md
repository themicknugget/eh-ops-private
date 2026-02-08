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
- **Tailscale auth key tagged with `tag:k8s`** (critical for ACL permissions)

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
- hostname: <HOSTNAME>  # Example: cloudbox2
  ipAddress: <INTERNAL_IP>  # Oracle Cloud internal IP (e.g., 10.0.0.173)
  controlPlane: false
  installDisk: /dev/sda
  talosImageURL: factory.talos.dev/oracle-installer/${SCHEMATIC_ID}
  machineSpec:
    mode: cloud
    secureboot: false
  certSANs:
    - <PUBLIC_IP>    # Oracle Cloud public IP (for provisioning access)
    - <INTERNAL_IP>  # Oracle Cloud internal IP
  extensionServices:
    - name: tailscale
      environment:
        - TS_AUTHKEY=${tailscaleAuthKey}  # Must be tagged with tag:k8s
        - TS_EXTRA_ARGS=--accept-routes   # Accept subnet routes
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
              - 100.64.0.0/10  # Use Tailscale IP as node IP
      cluster:
        controlPlane:
          endpoint: https://192.168.1.50:6443  # Unified control plane LB
  networkInterfaces:
    - deviceSelector:
        hardwareAddr: <MAC_ADDRESS>  # Get from Oracle Cloud console
      dhcp: false
      addresses:
        - <INTERNAL_IP>/24
      routes:
        - network: 0.0.0.0/0
          gateway: 10.0.0.1
        - network: 169.254.0.0/16  # Required for Oracle Cloud metadata
```

**Important Notes:**
- **TS_AUTHKEY must be tagged** with `tag:k8s` in Tailscale admin console for proper ACL permissions
- **validSubnets: 100.64.0.0/10** ensures kubelet uses Tailscale IP, enabling API server connectivity via Tailscale tunnel
- **certSANs** are primarily for talosctl access during the provisioning phase

### 4. Create Temporary Bootstrap Configuration

Generate a temporary single-node control plane config:

```bash
cd /tmp
talosctl gen config temp-cluster https://127.0.0.1:6443 \
  --install-disk /dev/sda \
  --install-image factory.talos.dev/installer/${SCHEMATIC_ID}:${TALOS_VERSION} \
  --additional-sans <HOSTNAME>-temp \
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
talosctl --talosconfig /tmp/talosconfig -e <PUBLIC_IP> -n <HOSTNAME>-temp bootstrap
```

**Why this works:**
- Node boots as a self-contained control plane
- No external dependencies needed
- Talos API becomes available for upgrade

### 6. Upgrade to Activate Extensions

Run the upgrade to activate system extensions:

```bash
talosctl --talosconfig /tmp/talosconfig \
  -e <PUBLIC_IP> -n <HOSTNAME>-temp \
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
  -e <PUBLIC_IP> -n <HOSTNAME>-temp \
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
  -e <PUBLIC_IP> -n <HOSTNAME>-temp \
  apply-config --file clusterconfig/eh-ops-<HOSTNAME>.yaml
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
NAME         STATUS   ROLES    AGE   VERSION
<HOSTNAME>   Ready    <none>   5m    v1.35.0
```

## Troubleshooting

### Tailscale Not Starting

Check service status:
```bash
talosctl -n <PUBLIC_IP> service ext-tailscale
```

Common issues:
- Auth key expired - generate new key in Tailscale admin console
- Auth key not tagged - ensure key is pre-tagged with `tag:k8s` for ACL permissions

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
kubectl describe node <HOSTNAME> | grep -A 10 "Conditions:"
```

Wait for Cilium to configure networking (usually 30-60 seconds).

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Oracle Cloud (10.0.0.0/24)                                  │
│                                                              │
│  ┌─────────────────────────────────────────┐               │
│  │ <HOSTNAME>                               │               │
│  │ - Internal IP: <INTERNAL_IP>             │               │
│  │ - Public IP: <PUBLIC_IP>                 │               │
│  │ - Tailscale IP: <TAILSCALE_IP>           │               │
│  │                                           │               │
│  │ ┌─────────────────────────────────────┐ │               │
│  │ │ Tailscale Extension                 │ │               │
│  │ │ - Accept routes: 192.168.1.51-53    │ │               │
│  │ │ - Accept routes: 192.168.1.50       │ │               │
│  │ │ - Tagged with tag:k8s               │ │               │
│  │ └─────────────────────────────────────┘ │               │
│  └─────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Tailscale VPN (WireGuard tunnel)
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
│  │ Tailscale Connector (3 replicas)            │           │
│  │ - Advertises: 192.168.1.50/32               │           │
│  │ - Advertises: 192.168.1.51-53/32            │           │
│  │ - Advertises: 10.244.0.0/16 (Pod CIDR)      │           │
│  │ - Advertises: 10.96.0.0/12 (Service CIDR)   │           │
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
6. **Tagged auth keys are critical** - Auth key MUST be pre-tagged with `tag:k8s` in Tailscale admin console for proper ACL permissions. Without this tag, Tailscale ACLs will block return traffic from Connector pods to the edge node, causing asymmetric routing failures.
7. **Use Tailscale IP as node IP** - Setting `validSubnets: [100.64.0.0/10]` ensures kubelet binds to the Tailscale IP, allowing the API server to reach it via the Tailscale tunnel. Do NOT use the Oracle Cloud internal IP (10.0.0.0/24) as the node IP.

## Placeholder Examples

When following this guide, replace placeholders with actual values from your Oracle Cloud instance:

| Placeholder | Example Value | Where to Find |
|-------------|---------------|---------------|
| `<HOSTNAME>` | `cloudbox2` | Choose a descriptive name |
| `<INTERNAL_IP>` | `10.0.0.173` | Oracle Cloud console → Instance → Primary VNIC |
| `<PUBLIC_IP>` | `150.136.113.236` | Oracle Cloud console → Instance → Public IP |
| `<TAILSCALE_IP>` | `100.121.18.12` | Tailscale admin console after node connects |
| `<MAC_ADDRESS>` | `02:00:17:0e:03:e8` | Oracle Cloud console → Instance → Attached VNICs → MAC Address |

## Related Documentation

- [Talos Oracle Cloud Guide](https://www.talos.dev/v1.12/talos-guides/install/cloud-platforms/oracle/)
- [Talos System Extensions](https://www.talos.dev/v1.12/talos-guides/configuration/system-extensions/)
- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets)
- [Tailscale ACLs and Tags](https://tailscale.com/kb/1068/acl-tags)
- [Oracle Cloud IMDS](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/gettingmetadata.htm)
