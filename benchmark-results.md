# Inference Backend Benchmark Results

**Date:** 2026-02-22 14:36 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory (GPU+CPU)  
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; 8192 context  
**Prompt:** ~90 tokens (fixed engineering question)  

**PP** = prompt processing speed (tok/s)  
**TG** = token generation speed (tok/s)  
**Load** = server startup + model load time  

## MiniMax M2.5 REAP 139B MXFP4
Quantization: MXFP4 · File size: ~71 GiB · Total params: 139B · Active params (MoE): 10B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 30s | 28.0 | 23.6 | flash-attn, q4_0 KV |
| Vulkan | 50s | 36.3 | 26.0 |  |
| CPU | 20s | 24.0 | 12.9 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=38.84 tg=23.56 (prompt=65 tok, gen=128 tok)
  Run 2: pp=22.37 tg=23.57 (prompt=1 tok, gen=128 tok)
  Run 3: pp=22.68 tg=23.56 (prompt=1 tok, gen=128 tok)
Vulkan:
  Run 1: pp=57.30 tg=25.29 (prompt=65 tok, gen=128 tok)
  Run 2: pp=25.61 tg=25.85 (prompt=1 tok, gen=128 tok)
  Run 3: pp=26.01 tg=26.79 (prompt=1 tok, gen=128 tok)
CPU:
  Run 1: pp=46.51 tg=12.90 (prompt=65 tok, gen=128 tok)
  Run 2: pp=12.71 tg=12.86 (prompt=1 tok, gen=128 tok)
  Run 3: pp=12.78 tg=12.86 (prompt=1 tok, gen=128 tok)
```

</details>

---

## MiniMax M2.5 REAP 172B Q4_K_M
Quantization: Q4_K_M · File size: ~97 GiB · Total params: 172B · Active params (MoE): 10B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 50s | 39.3 | 24.4 | flash-attn, q4_0 KV |
| Vulkan | 1m30s | 32.9 | 28.8 |  |
| CPU | 1m30s | 17.8 | 14.2 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=71.79 tg=24.37 (prompt=65 tok, gen=128 tok)
  Run 2: pp=23.74 tg=24.40 (prompt=1 tok, gen=128 tok)
  Run 3: pp=22.50 tg=24.37 (prompt=1 tok, gen=128 tok)
Vulkan:
  Run 1: pp=41.84 tg=28.16 (prompt=65 tok, gen=128 tok)
  Run 2: pp=28.47 tg=28.80 (prompt=1 tok, gen=128 tok)
  Run 3: pp=28.30 tg=29.43 (prompt=1 tok, gen=128 tok)
CPU:
  Run 1: pp=23.00 tg=13.05 (prompt=65 tok, gen=128 tok)
  Run 2: pp=15.24 tg=14.38 (prompt=1 tok, gen=128 tok)
  Run 3: pp=15.11 tg=15.27 (prompt=1 tok, gen=128 tok)
```

</details>

---

