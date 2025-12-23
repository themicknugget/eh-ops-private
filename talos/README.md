# Talos Linux Configuration

This directory contains the Talos Linux cluster configuration for the new cluster.

## Files

| File | Purpose |
|------|---------|
| `talconfig.yaml` | Main Talos cluster configuration |
| `talsecret.sops.yaml` | SOPS-encrypted cluster secrets |
| `clusterconfig/` | Generated node-specific configs (gitignored) |

## Quick Start

### 1. Install Dependencies

```bash
# talctl - Talos CLI
brew install talosctl

# SOPS - Secret encryption
brew install sops

# Age - SOPS encryption backend
brew install age
```

### 2. Generate Cluster Secrets

```bash
# Generate new cluster secrets
talosctl gen secrets --output-file secrets.yaml

# Encrypt with SOPS
sops --encrypt --age <AGE_RECIPIENT> secrets.yaml > talsecret.sops.yaml

# Clean up unencrypted secrets
rm secrets.yaml
```

### 3. Customize talconfig.yaml

Edit `talconfig.yaml` to define your nodes:

- **Cluster name**: `new-cluster` (update as needed)
- **Endpoint**: Update VIP address (192.168.1.50)
- **Nodes**: Add your node configurations under `nodes:`
  - `hostname`: Node hostname
  - `ipAddress`: Node IP address
  - `controlPlane`: true/false
  - `installDisk`: Target disk (find with `ls -la /dev/disk/by-id/`)
  - `networkInterfaces`: MAC address, IP, gateway

### 4. Generate Node Configs

```bash
# Generate node-specific machine configs
talosctl gen config \
  --config-secrets talsecret.sops.yaml \
  --output-dir clusterconfig \
  --output-types yaml \
  new-cluster https://192.168.1.50:6443
```

Or use talhelper if you prefer:

```bash
# Install talhelper
brew install talhelper

# Generate configs from talconfig.yaml
talhelper genconfig
```

### 5. Bootstrap the Cluster

```bash
# Apply config to first control plane node
talosctl apply-config --insecure \
  --nodes 192.168.1.51 \
  --file clusterconfig/controlplane-1.yaml

# Bootstrap etcd
talosctl bootstrap --endpoints 192.168.1.51

# Generate kubeconfig
talosctl kubeconfig --endpoints 192.168.1.51

# Verify cluster
kubectl get nodes
```

## Cluster Configuration

| Setting | Value |
|---------|-------|
| Talos Version | v1.12.0 |
| Kubernetes Version | v1.35.0 |
| Cluster Name | new-cluster |
| API Endpoint | https://192.168.1.50:6443 |
| Pod Network | 10.244.0.0/16 |
| Service Network | 10.96.0.0/12 |

## Hardware Requirements

### Control Plane Nodes (3 for HA)
- CPU: 4 cores minimum
- RAM: 4GB minimum
- Storage: 15GB+ (eMMC/NVMe/SSD)

### Worker Nodes
- CPU: 2 cores minimum
- RAM: 2GB minimum
- Storage: 15GB+ (NVMe/SSD recommended)

### Network
- 1Gbps network recommended
- Jumbo frames (MTU 9000) optional for bonded interfaces

## SOPS Configuration

This repo uses [Age](https://github.com/FiloSottile/age) for encryption.

To add your Age key:
```bash
# Generate new Age key (if needed)
age-keygen -o age-key.txt

# Get public key
age-keygen -y age-key.txt

# Update .sops.yaml with your recipient
```

## Troubleshooting

### talosctl can't connect
```bash
# Verify API endpoint is reachable
curl -k https://192.168.1.50:6443

# Check node is accessible
talosctl --talosconfig talosconfig version
```

### Node fails to boot
```bash
# Check console via BMC/serial
# Verify install disk is correct
# Verify network configuration
```

### Secrets decryption fails
```bash
# Verify SOPS config
cat .sops.yaml

# Test decryption
sops --decrypt talsecret.sops.yaml
```

## References

- [Talos Linux Documentation](https://www.talos.dev/v1.12/)
- [talhelper Documentation](https://budimanjojo.github.io/talhelper/)
- [SOPS Documentation](https://github.com/getsops/sops)
