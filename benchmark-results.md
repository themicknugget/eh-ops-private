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

