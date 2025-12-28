# ROCm Backend Investigation for Strix Halo (gfx1151)

**Issue:** eh-ops-ezu
**Started:** 2025-12-28
**Status:** BLOCKED - Waiting for ROCm fix
**Archived:** 2025-12-28

## Goal

Get ROCm backend working alongside Vulkan for llama.cpp on AMD Strix Halo (Radeon 8060S, gfx1151).

## Current Baseline

- **Working:** Vulkan RADV (721 t/s prompt, 63 t/s generation)
- **Broken:** ROCm hangs during model loading at "async uploads" phase

## Research Summary

### Root Cause Analysis

The hang at `load_all_data: using async uploads for device ROCm0` is caused by:

1. **hipMemcpy/hipMemcpyAsync blocking** - Memory copy operations can hang during `hsaKmtDeregisterMemory`
2. **Unpinned memory issues** - Pageable memory causes `hipMemcpyAsync` to block
3. **CWSR firmware bugs** - MES firmware 0x80 hang issues on gfx1151

### Key GitHub Issues

| Issue | Description | Status |
|-------|-------------|--------|
| ROCm #5534 | ROCm 7.0.2 crashes on gfx1151 MUL_MAT | Open |
| ROCm #5750 | Clock speeds stuck at idle | Open |
| ROCm #5151 | GPU hang on gfx1151 + Ubuntu | Open |
| llama.cpp #15018 | Slow loading past 64GB | Stale |

---

## Test Strategies

### Strategy 1: HSA_ENABLE_SDMA=0 with rocm-7.1.1

**Hypothesis:** Disabling SDMA engine may fix APU memory transfer issues.

**Image:** `kyuz0/amd-strix-halo-toolboxes:rocm-7.1.1`

**Environment Variables:**
```
HSA_ENABLE_SDMA=0
ROCBLAS_USE_HIPBLASLT=1
HIP_VISIBLE_DEVICES=0
```

**Result:**
- [x] PARTIAL SUCCESS - Got past "async uploads" hang!
- [ ] NEW HANG at "graph_reserve: reserving a graph for ubatch"

**Details:**
- ROCm detected GPU correctly: "Radeon 8060S Graphics, gfx1151"
- All 28 layers loaded to ROCm0
- KV cache initialized
- Hangs during graph reservation (kernel compilation phase)
- This is likely ROCm #5534 - MUL_MAT kernel issue

**Conclusion:** HSA_ENABLE_SDMA=0 fixes the async upload hang but kernel compilation still fails.

---

### Strategy 2: Minimal ROCm Image

**Hypothesis:** Minimal image with default gfx1151 target may have better compatibility.

**Image:** `introprose/llamacpp_rocm_minimal:latest`

**Environment Variables:**
```
HSA_ENABLE_SDMA=0
ROCBLAS_USE_HIPBLASLT=1
HIP_VISIBLE_DEVICES=0
```

**Result:**
- [x] SAME HANG at "graph_reserve: reserving a graph for ubatch"

**Details:**
- Different image, same behavior
- Confirms issue is with ROCm kernel compilation for gfx1151, not specific image
- Both kyuz0 and sirmo images have the same problem

**Conclusion:** Issue is fundamental to gfx1151 kernel execution, not image-specific.

---

### Strategy 3: GFX1100 Kernel Override

**Hypothesis:** Using gfx1100 kernels instead of native gfx1151 may work (reported 2-6x faster anyway).

**Image:** `kyuz0/amd-strix-halo-toolboxes:rocm-7.1.1`

**Environment Variables:**
```
HSA_ENABLE_SDMA=0
HSA_OVERRIDE_GFX_VERSION=11.0.0
ROCBLAS_USE_HIPBLASLT=1
HIP_VISIBLE_DEVICES=0
```

**Result:**
- [x] Override works - GPU detected as gfx1100
- [x] SAME HANG at "graph_reserve"
- [x] Tried with flash_attn=disabled - SAME HANG

**Details:**
- GPU correctly identified as `gfx1100 (0x1100)` instead of `gfx1151`
- Disabling flash attention didn't help
- Hang occurs during GGML graph reservation (kernel compilation)

**Conclusion:** Issue is not kernel target or flash attention - fundamental ROCm graph execution problem.

---

### Strategy 3: TheRock Nightly (ROCm 7.10)

**Hypothesis:** Preview/nightly builds may have gfx1151 fixes not in GA release.

**Image:** Need to build or find pre-built with TheRock 7.10

**Result:**
- [ ] Pending

---

### Strategy 4: CWSR Disable (Kernel Parameter)

**Hypothesis:** Disabling CWSR fixes MES firmware hangs.

**Requires:** Kernel parameter `amdgpu.cwsr_enable=0` on shadow node

**Result:**
- [ ] Pending (requires Talos config change)

---

### Strategy 5: Non-rocwmma Image

**Hypothesis:** rocwmma may cause issues per wiki guidance.

**Image:** `kyuz0/amd-strix-halo-toolboxes:rocm-7.1.1` (base, not rocwmma)

**Result:**
- [ ] Pending

---

## Test Log

### 2025-12-28

**Session Start**

- Created separate test namespace `llama-cpp-rocm-test`
- Working Vulkan deployment remains in `llama-cpp` namespace
- Starting sequential strategy testing

**Strategy Testing Results**

| Strategy | Image | Key Changes | Result |
|----------|-------|-------------|--------|
| 1 | rocm-7.1.1 | HSA_ENABLE_SDMA=0 | PARTIAL - past async uploads, hung at graph_reserve |
| 2 | llamacpp_rocm_minimal | Same env vars | SAME - hung at graph_reserve |
| 3a | rocm-7.1.1 | + HSA_OVERRIDE_GFX_VERSION=11.0.0 | SAME - gfx1100 detected, still hung |
| 3b | rocm-7.1.1 | + flash_attn=off | SAME - hung at graph_reserve |

**Key Finding:** The hang occurs at `graph_reserve: reserving a graph for ubatch` which is during GGML graph/kernel compilation. This is NOT:
- The original "async uploads" hang (fixed by HSA_ENABLE_SDMA=0)
- A flash attention issue
- A gfx1151 vs gfx1100 kernel issue

**Root Cause Hypothesis:** ROCm HIP backend hangs during hipLaunchKernel or similar calls during graph reservation. This may be related to:
- ROCm #5534: MUL_MAT kernel crash on gfx1151
- Kernel JIT compilation timeout/hang
- Missing CWSR disable (kernel param amdgpu.cwsr_enable=0)

**Recommended Next Steps:**
1. Try adding `amdgpu.cwsr_enable=0` kernel parameter to shadow node (requires Talos config change + reboot)
2. Monitor [ROCm #5534](https://github.com/ROCm/ROCm/issues/5534) for gfx1151 fixes
3. Continue using Vulkan backend which works reliably (721 t/s prompt, 63 t/s gen)

## Final Status

**BLOCKED** - ROCm hangs at kernel graph reservation on gfx1151. No workaround found in:
- ROCm 7.1.1 GA
- ROCm 7alpha nightly
- gfx1100 kernel override
- Flash attention on/off

**Vulkan works** - Use `kyuz0/amd-strix-halo-toolboxes:vulkan-radv` for production.

## To Resume Testing

```bash
# Re-enable in kustomization
kubectl apply -k kubernetes/infrastructure/llama-cpp-rocm-test/

# Or manually test with:
kubectl run rocm-test --image=kyuz0/amd-strix-halo-toolboxes:rocm-7.1.1 \
  --restart=Never --rm -it -- llama-cli --help
```

---

## Commands Reference

```bash
# Watch test pod logs
kubectl logs -f -n llama-cpp-rocm-test deploy/llama-rocm-test

# Check pod status
kubectl get pods -n llama-cpp-rocm-test -w

# Delete and recreate deployment
kubectl delete deploy llama-rocm-test -n llama-cpp-rocm-test
kubectl apply -k kubernetes/infrastructure/llama-cpp-rocm-test/

# Force Flux reconcile
flux reconcile kustomization infrastructure --with-source
```

## Success Criteria

1. ROCm backend loads model without hanging
2. Inference works with comparable or better performance than Vulkan
3. Can switch between Vulkan and ROCm via image tag change
