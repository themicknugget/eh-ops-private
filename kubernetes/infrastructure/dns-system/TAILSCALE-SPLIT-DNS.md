# Tailscale Split DNS Configuration for CoreDNS

After the dns-system components are deployed, configure Tailscale Split DNS to route queries to the CoreDNS service.

## Architecture

```
HTTPRoute resources
    ↓
external-dns watches HTTPRoutes
    ↓
external-dns writes A records to etcd
    ↓
CoreDNS reads from etcd and serves DNS
    ↓
Tailscale Split DNS forwards queries to CoreDNS
```

## Prerequisites

- dns-system namespace deployed with:
  - etcd (record storage)
  - CoreDNS (DNS server)
  - external-dns (HTTPRoute watcher)
- Tailscale Connector deployed and advertising service CIDR (10.96.0.0/12)
- Access to Tailscale Admin Console

## Configuration Steps

### 1. Get CoreDNS ClusterIP

```bash
kubectl get svc -n dns-system coredns-custom-coredns -o jsonpath='{.spec.clusterIP}'
```

Example output: `10.102.166.107` (will be an IP in 10.96.0.0/12 range)

### 2. Configure Split DNS in Tailscale Admin

1. Navigate to: https://login.tailscale.com/admin/dns
2. Scroll to **Nameservers** section
3. For each domain you want accessible via Tailscale:
   - Click **Add nameserver** → **Custom**
   - **Nameserver IP**: `<CoreDNS ClusterIP from step 1>`
   - **Restrict to domain**: `<domain>`
   - Click **Save**

**Domains to configure:**
| Domain | Purpose |
|--------|---------|
| `whydontyou.work` | Primary infrastructure |
| `eversafe.app` | Application domain |
| `codecrucible.app` | Application domain |

### 3. Verify Configuration

The DNS settings should show:
```
Custom nameservers:
10.x.x.x (restricted to whydontyou.work)
10.x.x.x (restricted to eversafe.app)
10.x.x.x (restricted to codecrucible.app)
```

## How It Works

```
Tailscale Client queries: grafana.whydontyou.work
    ↓
Tailscale MagicDNS intercepts query
    ↓
Split DNS rule matches whydontyou.work → forward to CoreDNS
    ↓
Connector routes to CoreDNS ClusterIP (10.96.0.0/12)
    ↓
CoreDNS queries etcd for record
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
dig app.codecrucible.app

# Expected output (IPs will vary based on Gateway):
# grafana.whydontyou.work. 300 IN A 192.168.1.65

# Test HTTPS access
curl -I https://grafana.whydontyou.work
```

## Troubleshooting

### DNS queries timing out
- Verify CoreDNS pods are running: `kubectl get pods -n dns-system -l app.kubernetes.io/name=coredns`
- Check etcd is healthy: `kubectl get pods -n dns-system -l app.kubernetes.io/name=etcd`
- Check Connector is advertising service CIDR: `kubectl get connector -n tailscale -o yaml`
- Verify routes are approved in Tailscale Admin Console

### DNS returns no records
- Verify HTTPRoute exists: `kubectl get httproute -A`
- Check external-dns is running: `kubectl get pods -n dns-system -l app=external-dns`
- Check external-dns logs: `kubectl logs -n dns-system -l app=external-dns`
- Verify records in etcd:
  ```bash
  kubectl exec -n dns-system etcd-0 -- etcdctl get /skydns --prefix
  ```
- Ensure Gateway has IP assigned: `kubectl get gateway -A`

### Split DNS not routing correctly
- Confirm CoreDNS ClusterIP is in service CIDR (10.96.0.0/12)
- Verify Tailscale client has route to service CIDR (`tailscale status`)
- Check Split DNS config in Tailscale Admin shows correct IP and domain

### external-dns not creating records
- Check external-dns can access Gateway API resources:
  ```bash
  kubectl auth can-i list httproutes.gateway.networking.k8s.io --as=system:serviceaccount:dns-system:external-dns
  ```
- Verify domain filters match HTTPRoute hostnames
- Check external-dns logs for errors:
  ```bash
  kubectl logs -n dns-system -l app=external-dns -f
  ```
