# Tailscale Split DNS Configuration for k8s-gateway

After k8s-gateway is deployed, configure Tailscale Split DNS to route queries to the k8s-gateway service.

k8s-gateway is configured with a catch-all domain (`.`), so it will respond to any HTTPRoute hostname. Tailscale Split DNS controls which domains are forwarded.

## Prerequisites

- k8s-gateway deployed and running in kube-system namespace
- Tailscale Connector deployed and advertising service CIDR (10.96.0.0/12)
- Access to Tailscale Admin Console

## Configuration Steps

### 1. Get k8s-gateway ClusterIP

```bash
kubectl get svc -n kube-system k8s-gateway -o jsonpath='{.spec.clusterIP}'
```

Example output: `10.102.166.107` (will be an IP in 10.96.0.0/12 range)

### 2. Configure Split DNS in Tailscale Admin

1. Navigate to: https://login.tailscale.com/admin/dns
2. Scroll to **Nameservers** section
3. For each domain you want accessible via Tailscale:
   - Click **Add nameserver** → **Custom**
   - **Nameserver IP**: `<k8s-gateway ClusterIP from step 1>`
   - **Restrict to domain**: `<domain>`
   - Click **Save**

**Domains to configure:**
| Domain | Purpose |
|--------|---------|
| `whydontyou.work` | Primary infrastructure |
| `eversafe.app` | Application domain |
| `holidayhacker.app` | Application domain |
| `codecrucible.app` | Application domain |

### 3. Verify Configuration

The DNS settings should show:
```
Custom nameservers:
10.102.166.107 (restricted to whydontyou.work)
10.102.166.107 (restricted to eversafe.app)
10.102.166.107 (restricted to holidayhacker.app)
10.102.166.107 (restricted to codecrucible.app)
```

## How It Works

```
Tailscale Client queries: app.eversafe.app
    ↓
Tailscale MagicDNS intercepts query
    ↓
Split DNS rule matches eversafe.app → forward to k8s-gateway
    ↓
Connector routes to k8s-gateway ClusterIP (10.96.0.0/12)
    ↓
k8s-gateway (catch-all) looks up HTTPRoute with matching hostname
    ↓
Returns Gateway LoadBalancer IP (e.g., 192.168.1.65)
    ↓
Client connects via Tailscale to Gateway IP
```

## Testing

From any Tailscale-connected device:

```bash
# Test DNS resolution for each domain
dig grafana.whydontyou.work
dig app.eversafe.app
dig app.holidayhacker.app

# Expected output (IPs will vary based on Gateway):
# grafana.whydontyou.work. 300 IN A 192.168.1.65

# Test HTTPS access
curl -I https://grafana.whydontyou.work
```

## Troubleshooting

### DNS queries timing out
- Verify k8s-gateway pod is running: `kubectl get pods -n kube-system -l app.kubernetes.io/name=k8s-gateway`
- Check Connector is advertising service CIDR: `kubectl get connector -n tailscale -o yaml`
- Verify routes are approved in Tailscale Admin Console

### DNS returns no records
- Verify HTTPRoute exists: `kubectl get httproute -A`
- Check HTTPRoute hostnames match queried domain
- Ensure Gateway has IP assigned: `kubectl get gateway -A`
- Check k8s-gateway logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=k8s-gateway`

### Split DNS not routing correctly
- Confirm k8s-gateway ClusterIP is in service CIDR (10.96.0.0/12)
- Verify Tailscale client has route to service CIDR (`tailscale status`)
- Check Split DNS config in Tailscale Admin shows correct IP and domain
