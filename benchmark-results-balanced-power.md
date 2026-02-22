# Inference Backend Benchmark Results

**Date:** 2026-02-22 18:05 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory (GPU+CPU)  
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; 8192 context  
**Prompt:** ~600 tokens (infrastructure scenario)  

**PP** = prompt processing speed (tok/s)  
**TG** = token generation speed (tok/s)  
**Load** = server startup + model load time  

## Qwen2.5 72B Instruct Q8_0
Quantization: Q8_0 · File size: ~77 GiB · Total params: 72B · Active params (MoE): 72B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 40s | 120.8 ±3.9 | 2.9 ±0.0 | flash-attn, q4_0 KV |
| Vulkan | 2m00s | 72.3 ±0.6 | 2.9 ±0.0 |  |
| CPU | — | — | — | incomplete |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=124.95 tg=2.87 (prompt=608 tok, gen=128 tok)
  Run 2: pp=120.23 tg=2.86 (prompt=608 tok, gen=128 tok)
  Run 3: pp=117.22 tg=2.82 (prompt=608 tok, gen=128 tok)
Vulkan:
  Run 1: pp=71.68 tg=2.88 (prompt=608 tok, gen=128 tok)
  Run 2: pp=72.78 tg=2.91 (prompt=608 tok, gen=128 tok)
  Run 3: pp=72.58 tg=2.89 (prompt=608 tok, gen=128 tok)
```

</details>

---

## Qwen3-Coder-Next 80B Q6_K
Quantization: Q6_K · File size: ~66 GiB · Total params: 80B · Active params (MoE): 3B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | — | — | — | not run |
| Vulkan | — | — | — | not run |
| CPU | — | — | — | not run |

<details><summary>Per-run detail</summary>

```
```

</details>

---

