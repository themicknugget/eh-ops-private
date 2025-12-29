# Claude Instructions

## YAML Comments Policy

When writing or modifying YAML files, follow these rules for comments:

### DO NOT add comments that:
- Restate what the YAML key already says (e.g., `# namespace` above `namespace:`)
- Describe obvious node/resource types (e.g., `# mini1 - Control plane node` when `controlPlane: true` exists)
- Duplicate information from `dependsOn`, `healthChecks`, or other declarative fields
- Repeat the same comment across multiple similar resources
- Include installation instructions (put those in README files)
- Exist in both a HelmRelease and its values file (pick one)

### DO add comments that:
- Explain WHY something non-obvious is configured a certain way
- Document security trade-offs (e.g., why privileged access is needed)
- Describe traffic flow or architecture that isn't self-evident
- Note timeouts or resource limits with context (e.g., "LLM inference can take a while")
- Reference external issues or documentation for complex workarounds

### Examples

**Bad:**
```yaml
# Cilium namespace
namespace: cilium
# Enable Cilium
enabled: true
# mini1 - Control plane node
hostname: mini1
controlPlane: true
```

**Good:**
```yaml
# Required for eBPF programs to access kernel headers
privileged: true
# LLM inference can take 30s+ for long generations
timeout: 60s
# Traffic flow: Gateway (HTTPS) -> Envoy -> Backend
```

### Rule of Thumb
If deleting the comment would lose important context that isn't expressed elsewhere in the file, keep it. Otherwise, remove it.
