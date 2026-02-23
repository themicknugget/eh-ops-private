# Inference Backend Benchmark Results

**Date:** 2026-02-22 19:42 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory (GPU+CPU)  
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; 8192 context  
**Prompt:** ~600 tokens (infrastructure scenario)  

**PP** = prompt processing speed (tok/s)  
**TG** = token generation speed (tok/s)  
**Load** = server startup + model load time  

## MiniMax M2.5 REAP 139B MXFP4
Quantization: MXFP4 · File size: ~71 GiB · Total params: 139B · Active params (MoE): 10B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 50s | 172.8 ±2.9 | 22.7 ±0.5 | flash-attn, q4_0 KV |
| Vulkan | 40s | 183.5 ±6.0 | 25.4 ±0.4 |  |
| CPU | 30s | 50.1 ±1.1 | 11.6 ±0.2 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=176.09 tg=23.21 (prompt=579 tok, gen=128 tok)
  Run 2: pp=171.02 tg=22.66 (prompt=579 tok, gen=128 tok)
  Run 3: pp=171.18 tg=22.22 (prompt=579 tok, gen=128 tok)
Vulkan:
  Run 1: pp=176.60 tg=25.04 (prompt=579 tok, gen=128 tok)
  Run 2: pp=187.26 tg=25.45 (prompt=579 tok, gen=128 tok)
  Run 3: pp=186.71 tg=25.80 (prompt=579 tok, gen=128 tok)
CPU:
  Run 1: pp=51.32 tg=11.88 (prompt=579 tok, gen=128 tok)
  Run 2: pp=49.63 tg=11.49 (prompt=579 tok, gen=128 tok)
  Run 3: pp=49.40 tg=11.39 (prompt=579 tok, gen=128 tok)
```

</details>

---

## MiniMax M2.5 REAP 172B Q4_K_M
Quantization: Q4_K_M · File size: ~97 GiB · Total params: 172B · Active params (MoE): 10B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 1m00s | 181.7 ±3.2 | 22.8 ±0.7 | flash-attn, q4_0 KV |
| Vulkan | 1m30s | 133.9 ±5.5 | 28.0 ±0.6 |  |
| CPU | 1m41s | 57.2 ±10.9 | 11.9 ±0.9 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=184.54 tg=23.47 (prompt=579 tok, gen=128 tok)
  Run 2: pp=182.23 tg=22.92 (prompt=579 tok, gen=128 tok)
  Run 3: pp=178.17 tg=22.07 (prompt=579 tok, gen=128 tok)
Vulkan:
  Run 1: pp=127.54 tg=27.34 (prompt=579 tok, gen=128 tok)
  Run 2: pp=137.47 tg=28.48 (prompt=579 tok, gen=128 tok)
  Run 3: pp=136.66 tg=28.16 (prompt=579 tok, gen=128 tok)
CPU:
  Run 1: pp=44.60 tg=12.52 (prompt=579 tok, gen=128 tok)
  Run 2: pp=63.81 tg=12.37 (prompt=579 tok, gen=128 tok)
  Run 3: pp=63.26 tg=10.86 (prompt=579 tok, gen=128 tok)
```

</details>

---

## DeepSeek R1 Distill Llama 70B Q4_K_M
Quantization: Q4_K_M · File size: ~43 GiB · Total params: 70B · Active params (MoE): 70B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 20s | 119.5 ±2.3 | 4.9 ±0.0 | flash-attn, q4_0 KV |
| Vulkan | 20s | 75.4 ±1.9 | 5.0 ±0.0 |  |
| CPU | 31s | 17.1 ±0.3 | 2.3 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=117.69 tg=4.90 (prompt=550 tok, gen=128 tok)
  Run 2: pp=122.11 tg=4.88 (prompt=550 tok, gen=128 tok)
  Run 3: pp=118.58 tg=4.83 (prompt=550 tok, gen=128 tok)
Vulkan:
  Run 1: pp=73.21 tg=5.04 (prompt=550 tok, gen=128 tok)
  Run 2: pp=76.75 tg=5.05 (prompt=550 tok, gen=128 tok)
  Run 3: pp=76.31 tg=5.06 (prompt=550 tok, gen=128 tok)
CPU:
  Run 1: pp=16.81 tg=2.30 (prompt=550 tok, gen=128 tok)
  Run 2: pp=17.04 tg=2.34 (prompt=550 tok, gen=128 tok)
  Run 3: pp=17.35 tg=2.34 (prompt=550 tok, gen=128 tok)
```

</details>

---

## Devstral-2 123B Q5_K_M
Quantization: Q5_K_M · File size: ~88 GiB · Total params: 123B · Active params (MoE): 123B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 50s | 67.5 ±1.6 | 2.4 ±0.0 | flash-attn, q4_0 KV |
| Vulkan | 1m01s | 39.3 ±0.8 | 2.5 ±0.0 |  |
| CPU | 30s | 4.3 ±0.0 | 1.1 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=65.89 tg=2.40 (prompt=595 tok, gen=128 tok)
  Run 2: pp=69.00 tg=2.37 (prompt=595 tok, gen=128 tok)
  Run 3: pp=67.77 tg=2.41 (prompt=595 tok, gen=128 tok)
Vulkan:
  Run 1: pp=38.37 tg=2.43 (prompt=595 tok, gen=128 tok)
  Run 2: pp=39.74 tg=2.48 (prompt=595 tok, gen=128 tok)
  Run 3: pp=39.73 tg=2.48 (prompt=595 tok, gen=128 tok)
CPU:
  Run 1: pp=4.32 tg=1.14 (prompt=595 tok, gen=128 tok)
  Run 2: pp=4.31 tg=1.13 (prompt=595 tok, gen=128 tok)
  Run 3: pp=4.31 tg=1.12 (prompt=595 tok, gen=128 tok)
```

</details>

---

## Llama 3.3 70B Instruct Q8_0
Quantization: Q8_0 · File size: ~75 GiB · Total params: 70B · Active params (MoE): 70B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 40s | 107.1 ±2.1 | 2.9 ±0.0 | flash-attn, q4_0 KV |
| Vulkan | 50s | 82.4 ±0.5 | 3.0 ±0.0 |  |
| CPU | 30s | 13.2 ±0.0 | 1.4 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=109.42 tg=2.93 (prompt=590 tok, gen=128 tok)
  Run 2: pp=106.30 tg=2.95 (prompt=590 tok, gen=128 tok)
  Run 3: pp=105.49 tg=2.94 (prompt=590 tok, gen=128 tok)
Vulkan:
  Run 1: pp=81.87 tg=2.95 (prompt=590 tok, gen=128 tok)
  Run 2: pp=82.87 tg=2.97 (prompt=590 tok, gen=128 tok)
  Run 3: pp=82.55 tg=2.97 (prompt=590 tok, gen=128 tok)
CPU:
  Run 1: pp=13.17 tg=1.36 (prompt=590 tok, gen=128 tok)
  Run 2: pp=13.19 tg=1.36 (prompt=590 tok, gen=128 tok)
  Run 3: pp=13.18 tg=1.36 (prompt=590 tok, gen=128 tok)
```

</details>

---

## Llama 4 Scout 17Bx16E UD-Q4_K_XL
Quantization: UD-Q4_K_XL · File size: ~62 GiB · Total params: 109B · Active params (MoE): 17B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 30s | 266.9 ±4.1 | 18.6 ±0.3 | flash-attn, q4_0 KV |
| Vulkan | 31s | 126.5 ±8.0 | 18.7 ±0.8 |  |
| CPU | 41s | 53.2 ±0.1 | 9.4 ±0.1 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=271.63 tg=18.98 (prompt=550 tok, gen=128 tok)
  Run 2: pp=264.97 tg=18.38 (prompt=550 tok, gen=128 tok)
  Run 3: pp=264.08 tg=18.54 (prompt=550 tok, gen=128 tok)
Vulkan:
  Run 1: pp=122.53 tg=19.16 (prompt=550 tok, gen=128 tok)
  Run 2: pp=121.19 tg=17.84 (prompt=550 tok, gen=128 tok)
  Run 3: pp=135.70 tg=19.21 (prompt=550 tok, gen=128 tok)
CPU:
  Run 1: pp=53.21 tg=9.39 (prompt=550 tok, gen=128 tok)
  Run 2: pp=53.13 tg=9.52 (prompt=550 tok, gen=128 tok)
  Run 3: pp=53.21 tg=9.36 (prompt=550 tok, gen=128 tok)
```

</details>

---

## Qwen3-235B-A22B Q2_K
Quantization: Q2_K · File size: ~86 GiB · Total params: 235B · Active params (MoE): 22B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 40s | 107.0 ±2.5 | 16.9 ±0.5 | flash-attn, q4_0 KV |
| Vulkan | 1m01s | 98.5 ±2.7 | 19.6 ±0.1 |  |
| CPU | 50s | 25.4 ±2.5 | 8.2 ±0.5 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=108.98 tg=17.36 (prompt=587 tok, gen=128 tok)
  Run 2: pp=107.85 tg=16.88 (prompt=587 tok, gen=128 tok)
  Run 3: pp=104.24 tg=16.40 (prompt=587 tok, gen=128 tok)
Vulkan:
  Run 1: pp=95.45 tg=19.70 (prompt=587 tok, gen=128 tok)
  Run 2: pp=100.45 tg=19.66 (prompt=587 tok, gen=128 tok)
  Run 3: pp=99.61 tg=19.47 (prompt=587 tok, gen=128 tok)
CPU:
  Run 1: pp=22.66 tg=8.75 (prompt=587 tok, gen=128 tok)
  Run 2: pp=27.71 tg=7.95 (prompt=587 tok, gen=128 tok)
  Run 3: pp=25.82 tg=7.79 (prompt=587 tok, gen=128 tok)
```

</details>

---

## Qwen2.5 72B Instruct Q8_0
Quantization: Q8_0 · File size: ~77 GiB · Total params: 72B · Active params (MoE): 72B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 40s | 123.1 ±3.3 | 2.9 ±0.0 | flash-attn, q4_0 KV |
| Vulkan | 1m40s | 60.4 ±0.6 | 2.9 ±0.0 |  |
| CPU | 30s | 12.3 ±0.4 | 1.3 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=126.40 tg=2.87 (prompt=608 tok, gen=128 tok)
  Run 2: pp=122.99 tg=2.86 (prompt=608 tok, gen=128 tok)
  Run 3: pp=119.79 tg=2.85 (prompt=608 tok, gen=128 tok)
Vulkan:
  Run 1: pp=59.78 tg=2.86 (prompt=608 tok, gen=128 tok)
  Run 2: pp=60.84 tg=2.89 (prompt=608 tok, gen=128 tok)
  Run 3: pp=60.56 tg=2.89 (prompt=608 tok, gen=128 tok)
CPU:
  Run 1: pp=12.01 tg=1.28 (prompt=608 tok, gen=128 tok)
  Run 2: pp=12.20 tg=1.32 (prompt=608 tok, gen=128 tok)
  Run 3: pp=12.81 tg=1.32 (prompt=608 tok, gen=128 tok)
```

</details>

---

## Qwen3-Coder-Next 80B Q6_K
Quantization: Q6_K · File size: ~66 GiB · Total params: 80B · Active params (MoE): 3B

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| ROCm 7.2 | 30s | 219.6 ±2.0 | 33.0 ±0.7 | flash-attn, q4_0 KV |
| Vulkan | 40s | 318.9 ±26.3 | 38.1 ±0.3 |  |
| CPU | 20s | 93.6 ±2.3 | 11.7 ±0.1 | no GPU offload |

<details><summary>Per-run detail</summary>

```
ROCm 7.2:
  Run 1: pp=218.12 tg=33.76 (prompt=587 tok, gen=128 tok)
  Run 2: pp=218.88 tg=32.83 (prompt=587 tok, gen=128 tok)
  Run 3: pp=221.84 tg=32.36 (prompt=587 tok, gen=128 tok)
Vulkan:
  Run 1: pp=288.60 tg=37.82 (prompt=587 tok, gen=128 tok)
  Run 2: pp=336.48 tg=38.11 (prompt=587 tok, gen=128 tok)
  Run 3: pp=331.46 tg=38.45 (prompt=587 tok, gen=128 tok)
CPU:
  Run 1: pp=93.19 tg=11.80 (prompt=587 tok, gen=128 tok)
  Run 2: pp=91.56 tg=11.65 (prompt=587 tok, gen=128 tok)
  Run 3: pp=96.11 tg=11.61 (prompt=587 tok, gen=128 tok)
```

</details>

---

## New Model Benchmarks — K8s Jobs (Vulkan/ROCm direct)

**Date:** 2026-02-23 09:37 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory  
**Access:** K8s Job on shadow node (no LiteLLM, no KubeElasti interference)  
**Benchmark:** 3-run average after 1 warmup; 128 max tokens; 8192 context  
**Prompt:** ~600 tokens (infrastructure scenario)  
**Vulkan:** mmap enabled (no --no-mmap); LLAMA_HIP_UMA=ON  
**ROCm:** --no-mmap; flash-attn; q4_0 KV cache  

**PP** = prompt processing speed (tok/s, from llama.cpp timings field)  
**TG** = token generation speed (tok/s)  
**Load** = server start + model load time (8K context)  

| Model | Quant | Size | Params | Active | Backend | Load | PP (tok/s) | TG (tok/s) |
|-------|-------|------|--------|--------|---------|------|-----------|-----------|
| Phi-4-mini Instruct Q8_0 | Q8_0 | ~4 GiB | 3.8B | 3.8B | Vulkan (mmap) | 10s | 1416.7 ±275.2 | 50.2 ±0.5 |
| DeepSeek R1-0528 Qwen3 8B Q8_0 | Q8_0 | ~8 GiB | 8B | 8B | Vulkan (mmap) | 10s | 700.8 ±64.9 | 26.6 ±0.0 |
| GPT-OSS 20B Q8_0 | Q8_0 | ~12 GiB | 20B | ~4B | Vulkan (mmap) | 10s | 947.1 ±106.7 | 77.2 ±0.2 |
| Phi-4-reasoning-plus Q8_0 | Q8_0 | ~16 GiB | 14B | 14B | Vulkan (mmap) | 10s | 467.4 ±5.2 | 14.5 ±0.0 |
| Mistral Small 3.1 24B Instruct Q5_K_M | Q5_K_M | ~17 GiB | 24B | 24B | Vulkan (mmap) | 10s | 250.8 ±2.2 | 13.2 ±0.0 |
| GLM-4.7 Flash 30B-A3B Q4_K_M | Q4_K_M | ~19 GiB | 30B | 3B | Vulkan (mmap) | 10s | 547.2 ±132.3 | 62.1 ±1.3 |
| Qwen2.5-Coder 32B Instruct Q4_K_M | Q4_K_M | ~20 GiB | 32B | 32B | Vulkan (mmap) | 10s | 202.3 ±5.2 | 11.1 ±0.0 |
| Gemma 3 27B Instruct Q6_K (vision) | Q6_K | ~22 GiB | 27B | 27B | Vulkan (mmap) | — | — | ERROR: server died |
| Qwen3-VL 30B-A3B Instruct Q4_K_M (vision) | Q4_K_M | ~19 GiB | 30B | 3B | Vulkan (mmap) | — | — | ERROR: server died |
| Qwen2.5-VL 72B Instruct IQ4_XS (vision) | IQ4_XS | ~40 GiB | 72B | 72B | Vulkan (mmap) | — | — | ERROR: server died |
| GPT-OSS 120B Q4_K_M | Q4_K_M | ~63 GiB | 120B | ~20B | Vulkan (mmap) | 40s | 332.4 ±32.2 | 57.0 ±0.7 |
| Qwen3-Coder-Next 80B Q6_K | Q6_K | ~66 GiB | 80B | 3B | Vulkan (mmap) | 1m30s | 324.2 ±28.9 | 38.0 ±0.1 |
| Command-A 111B IQ4_XS | IQ4_XS | ~60 GiB | 111B | ~14B | Vulkan (mmap) | 30s | 36.8 ±0.0 | 3.4 ±0.0 |
| MiniMax M2.5 REAP 139B MXFP4 [reference] | MXFP4 | ~71 GiB | 139B | 10B | ROCm 7.2 (--no-mmap) | 50s | 166.8 ±3.2 | 22.7 ±0.5 |

<details><summary>Per-run detail</summary>

```
Phi-4-mini Instruct Q8_0:
  Run 1: pp=1101.93 tg=50.68 (prompt=545 tok, gen=128 tok)
  Run 2: pp=1611.43 tg=50.05 (prompt=545 tok, gen=128 tok)
  Run 3: pp=1536.83 tg=49.77 (prompt=545 tok, gen=128 tok)
DeepSeek R1-0528 Qwen3 8B Q8_0:
  Run 1: pp=626.97 tg=26.59 (prompt=582 tok, gen=128 tok)
  Run 2: pp=748.74 tg=26.55 (prompt=582 tok, gen=128 tok)
  Run 3: pp=726.69 tg=26.51 (prompt=582 tok, gen=128 tok)
GPT-OSS 20B Q8_0:
  Run 1: pp=830.96 tg=77.26 (prompt=545 tok, gen=128 tok)
  Run 2: pp=969.78 tg=76.99 (prompt=542 tok, gen=128 tok)
  Run 3: pp=1040.64 tg=77.29 (prompt=542 tok, gen=128 tok)
Phi-4-reasoning-plus Q8_0:
  Run 1: pp=461.58 tg=14.51 (prompt=555 tok, gen=128 tok)
  Run 2: pp=471.45 tg=14.51 (prompt=552 tok, gen=128 tok)
  Run 3: pp=469.17 tg=14.51 (prompt=552 tok, gen=128 tok)
Mistral Small 3.1 24B Instruct Q5_K_M:
  Run 1: pp=251.68 tg=13.21 (prompt=593 tok, gen=128 tok)
  Run 2: pp=252.50 tg=13.20 (prompt=590 tok, gen=128 tok)
  Run 3: pp=248.26 tg=13.21 (prompt=590 tok, gen=128 tok)
GLM-4.7 Flash 30B-A3B Q4_K_M:
  Run 1: pp=394.49 tg=63.51 (prompt=553 tok, gen=128 tok)
  Run 2: pp=619.78 tg=62.02 (prompt=553 tok, gen=128 tok)
  Run 3: pp=627.20 tg=60.89 (prompt=553 tok, gen=128 tok)
Qwen2.5-Coder 32B Instruct Q4_K_M:
  Run 1: pp=196.36 tg=11.07 (prompt=608 tok, gen=128 tok)
  Run 2: pp=205.13 tg=11.09 (prompt=608 tok, gen=128 tok)
  Run 3: pp=205.58 tg=11.06 (prompt=608 tok, gen=128 tok)
GPT-OSS 120B Q4_K_M:
  Run 1: pp=296.62 tg=56.74 (prompt=545 tok, gen=128 tok)
  Run 2: pp=341.64 tg=56.45 (prompt=542 tok, gen=128 tok)
  Run 3: pp=358.97 tg=57.69 (prompt=542 tok, gen=128 tok)
Qwen3-Coder-Next 80B Q6_K:
  Run 1: pp=290.84 tg=37.83 (prompt=587 tok, gen=128 tok)
  Run 2: pp=342.13 tg=38.11 (prompt=587 tok, gen=128 tok)
  Run 3: pp=339.65 tg=38.02 (prompt=587 tok, gen=128 tok)
Command-A 111B IQ4_XS:
  Run 1: pp=36.82 tg=3.37 (prompt=597 tok, gen=128 tok)
  Run 2: pp=36.76 tg=3.37 (prompt=594 tok, gen=128 tok)
  Run 3: pp=36.74 tg=3.37 (prompt=594 tok, gen=128 tok)
MiniMax M2.5 REAP 139B MXFP4 [reference]:
  Run 1: pp=170.18 tg=23.24 (prompt=579 tok, gen=128 tok)
  Run 2: pp=166.41 tg=22.68 (prompt=579 tok, gen=128 tok)
  Run 3: pp=163.78 tg=22.29 (prompt=579 tok, gen=128 tok)
```

</details>


---

## Vision Model Benchmarks (re-run after download fix)

**Date:** 2026-02-23 09:59 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory  
**Access:** K8s Job on shadow node (Vulkan backend, mmap enabled)  
**Benchmark:** 3-run average after 1 warmup; 128 max tokens; 8192 context  
**Note:** Text-only benchmark (vision/mmproj not tested); prior downloads failed due to include bug  

| Model | Quant | Size | Params | Active | Load | PP (tok/s) | TG (tok/s) |
|-------|-------|------|--------|--------|------|-----------|-----------|
| Qwen3-VL 30B-A3B Instruct Q4_K_M (vision) | Q4_K_M | ~19 GiB | 30B | 3B | 10s | 696.0 ±104.7 | 79.9 ±0.9 |
| Gemma 3 27B Instruct Q6_K (vision) | Q6_K | ~22 GiB | 27B | 27B | — | — | — |
| Qwen2.5-VL 72B Instruct IQ4_XS (vision) | IQ4_XS | ~40 GiB | 72B | 72B | — | — | — |

<details><summary>Per-run detail</summary>

```
Qwen3-VL 30B-A3B Instruct Q4_K_M (vision):
  Run 1: pp=575.11 tg=78.83 (prompt=587 tok, gen=128 tok)
  Run 2: pp=757.37 tg=80.67 (prompt=587 tok, gen=128 tok)
  Run 3: pp=755.54 tg=80.17 (prompt=587 tok, gen=128 tok)
```

</details>


---

## Vision Model Benchmarks (re-run after download fix)

**Date:** 2026-02-23 10:00 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory  
**Access:** K8s Job on shadow node (Vulkan backend, mmap enabled)  
**Benchmark:** 3-run average after 1 warmup; 128 max tokens; 8192 context  
**Note:** Text-only benchmark (vision/mmproj not tested); prior downloads failed due to include bug  

| Model | Quant | Size | Params | Active | Load | PP (tok/s) | TG (tok/s) |
|-------|-------|------|--------|--------|------|-----------|-----------|
| Qwen3-VL 30B-A3B Instruct Q4_K_M (vision) | Q4_K_M | ~19 GiB | 30B | 3B | 10s | 696.0 ±104.7 | 79.9 ±0.9 |
| Gemma 3 27B Instruct Q6_K (vision) | Q6_K | ~22 GiB | 27B | 27B | 10s | 184.4 ±3.3 | 9.4 ±0.1 |
| Qwen2.5-VL 72B Instruct IQ4_XS (vision) | IQ4_XS | ~40 GiB | 72B | 72B | — | — | — |

<details><summary>Per-run detail</summary>

```
Qwen3-VL 30B-A3B Instruct Q4_K_M (vision):
  Run 1: pp=575.11 tg=78.83 (prompt=587 tok, gen=128 tok)
  Run 2: pp=757.37 tg=80.67 (prompt=587 tok, gen=128 tok)
  Run 3: pp=755.54 tg=80.17 (prompt=587 tok, gen=128 tok)
Gemma 3 27B Instruct Q6_K (vision):
  Run 1: pp=180.69 tg=9.41 (prompt=599 tok, gen=128 tok)
  Run 2: pp=186.90 tg=9.39 (prompt=599 tok, gen=128 tok)
  Run 3: pp=185.71 tg=9.32 (prompt=599 tok, gen=128 tok)
```

</details>


---

## Vision Model Benchmarks (re-run after download fix)

**Date:** 2026-02-23 10:03 UTC  
**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory  
**Access:** K8s Job on shadow node (Vulkan backend, mmap enabled)  
**Benchmark:** 3-run average after 1 warmup; 128 max tokens; 8192 context  
**Note:** Text-only benchmark (vision/mmproj not tested); prior downloads failed due to include bug  

| Model | Quant | Size | Params | Active | Load | PP (tok/s) | TG (tok/s) |
|-------|-------|------|--------|--------|------|-----------|-----------|
| Qwen3-VL 30B-A3B Instruct Q4_K_M (vision) | Q4_K_M | ~19 GiB | 30B | 3B | 10s | 696.0 ±104.7 | 79.9 ±0.9 |
| Gemma 3 27B Instruct Q6_K (vision) | Q6_K | ~22 GiB | 27B | 27B | 10s | 184.4 ±3.3 | 9.4 ±0.1 |
| Qwen2.5-VL 72B Instruct IQ4_XS (vision) | IQ4_XS | ~40 GiB | 72B | 72B | 21s | 82.2 ±0.2 | 5.3 ±0.0 |

<details><summary>Per-run detail</summary>

```
Qwen3-VL 30B-A3B Instruct Q4_K_M (vision):
  Run 1: pp=575.11 tg=78.83 (prompt=587 tok, gen=128 tok)
  Run 2: pp=757.37 tg=80.67 (prompt=587 tok, gen=128 tok)
  Run 3: pp=755.54 tg=80.17 (prompt=587 tok, gen=128 tok)
Gemma 3 27B Instruct Q6_K (vision):
  Run 1: pp=180.69 tg=9.41 (prompt=599 tok, gen=128 tok)
  Run 2: pp=186.90 tg=9.39 (prompt=599 tok, gen=128 tok)
  Run 3: pp=185.71 tg=9.32 (prompt=599 tok, gen=128 tok)
Qwen2.5-VL 72B Instruct IQ4_XS (vision):
  Run 1: pp=82.38 tg=5.24 (prompt=598 tok, gen=128 tok)
  Run 2: pp=82.27 tg=5.28 (prompt=598 tok, gen=128 tok)
  Run 3: pp=82.07 tg=5.27 (prompt=598 tok, gen=128 tok)
```

</details>

