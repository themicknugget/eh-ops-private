# Inference Benchmark Results

**Hardware:** AMD Strix Halo — Radeon 8060S (gfx1151), 128 GB unified memory (GPU+CPU)
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; 8192 context
**Prompt:** ~600 tokens (infrastructure scenario)
**Vulkan:** LLAMA_HIP_UMA=ON, mmap
**ROCm:** ROCm 7.2, --no-mmap, flash-attn, q4_0 KV cache

**PP** = prompt processing speed (tok/s)
**TG** = token generation speed (tok/s)
**Load** = server startup + model load time (8192 context)

---

## Summary

Sorted by Vulkan TG speed descending. ‡ = also benchmarked on ROCm and CPU (see detail section). *(vision)* = multimodal model, benchmarked text-only.

| Model | Quant | Params (active) | Vulkan Load | Vulkan PP | Vulkan TG |
|-------|-------|-----------------|-------------|-----------|-----------|
| Qwen3-VL 30B-A3B Instruct *(vision)* | Q4_K_M | 30B (3B MoE) | 10s | 696 ±105 | 79.9 ±0.9 |
| GPT-OSS 20B | Q8_0 | 20B (~4B MoE) | 10s | 947 ±107 | 77.2 ±0.2 |
| GLM-4.7 Flash 30B-A3B | Q4_K_M | 30B (3B MoE) | 10s | 547 ±132 | 62.1 ±1.3 |
| GPT-OSS 120B | Q4_K_M | 120B (~20B MoE) | 40s | 332 ±32 | 57.0 ±0.7 |
| Phi-4-mini Instruct | Q8_0 | 3.8B | 10s | 1417 ±275 | 50.2 ±0.5 |
| Qwen3-Coder-Next 80B ‡ | Q6_K | 80B (3B MoE) | 40s | 319 ±26 | 38.1 ±0.3 |
| MiniMax M2.5 REAP 172B ‡ | Q4_K_M | 172B (10B MoE) | 1m30s | 134 ±6 | 28.0 ±0.6 |
| DeepSeek R1-0528 Qwen3 8B | Q8_0 | 8B | 10s | 701 ±65 | 26.6 ±0.0 |
| MiniMax M2.5 REAP 139B ‡ | MXFP4 | 139B (10B MoE) | 40s | 184 ±6 | 25.4 ±0.4 |
| Qwen3-235B-A22B ‡ | Q2_K | 235B (22B MoE) | 1m01s | 99 ±3 | 19.6 ±0.1 |
| Llama 4 Scout 17Bx16E ‡ | UD-Q4_K_XL | 109B (17B MoE) | 31s | 127 ±8 | 18.7 ±0.8 |
| Phi-4-reasoning-plus | Q8_0 | 14B | 10s | 467 ±5 | 14.5 ±0.0 |
| Mistral Small 3.1 24B Instruct | Q5_K_M | 24B | 10s | 251 ±2 | 13.2 ±0.0 |
| Qwen2.5-Coder 32B Instruct | Q4_K_M | 32B | 10s | 202 ±5 | 11.1 ±0.0 |
| Gemma 3 27B Instruct *(vision)* | Q6_K | 27B | 10s | 184 ±3 | 9.4 ±0.1 |
| Qwen2.5-VL 72B Instruct *(vision)* | IQ4_XS | 72B | 21s | 82 ±0.2 | 5.3 ±0.0 |
| DeepSeek R1 Distill Llama 70B ‡ | Q4_K_M | 70B | 20s | 75 ±2 | 5.0 ±0.0 |
| Command-A 111B | IQ4_XS | 111B (~14B MoE) | 30s | 37 ±0.0 | 3.4 ±0.0 |
| Llama 3.3 70B Instruct ‡ | Q8_0 | 70B | 50s | 82 ±1 | 3.0 ±0.0 |
| Qwen2.5 72B Instruct ‡ | Q8_0 | 72B | 1m40s | 60 ±1 | 2.9 ±0.0 |
| Devstral-2 123B ‡ | Q5_K_M | 123B | 1m01s | 39 ±1 | 2.5 ±0.0 |

---

## Detail

---

## Qwen3-VL 30B-A3B Instruct Q4_K_M *(vision)*
Quantization: Q4_K_M · Params: 30B total / 3B active (MoE) · File: ~19 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 696.0 ±104.7 | 79.9 ±0.9 | text-only (no mmproj) |

<details><summary>Per-run detail</summary>

```
Run 1: pp=575.11 tg=78.83 (prompt=587 tok, gen=128 tok)
Run 2: pp=757.37 tg=80.67 (prompt=587 tok, gen=128 tok)
Run 3: pp=755.54 tg=80.17 (prompt=587 tok, gen=128 tok)
```

</details>

---

## GPT-OSS 20B Q8_0
Quantization: Q8_0 · Params: 20B total / ~4B active (MoE) · File: ~12 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 947.1 ±106.7 | 77.2 ±0.2 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=830.96 tg=77.26 (prompt=545 tok, gen=128 tok)
Run 2: pp=969.78 tg=76.99 (prompt=542 tok, gen=128 tok)
Run 3: pp=1040.64 tg=77.29 (prompt=542 tok, gen=128 tok)
```

</details>

---

## GLM-4.7 Flash 30B-A3B Q4_K_M
Quantization: Q4_K_M · Params: 30B total / 3B active (MoE) · File: ~19 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 547.2 ±132.3 | 62.1 ±1.3 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=394.49 tg=63.51 (prompt=553 tok, gen=128 tok)
Run 2: pp=619.78 tg=62.02 (prompt=553 tok, gen=128 tok)
Run 3: pp=627.20 tg=60.89 (prompt=553 tok, gen=128 tok)
```

</details>

---

## GPT-OSS 120B Q4_K_M
Quantization: Q4_K_M · Params: 120B total / ~20B active (MoE) · File: ~63 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 40s | 332.4 ±32.2 | 57.0 ±0.7 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=296.62 tg=56.74 (prompt=545 tok, gen=128 tok)
Run 2: pp=341.64 tg=56.45 (prompt=542 tok, gen=128 tok)
Run 3: pp=358.97 tg=57.69 (prompt=542 tok, gen=128 tok)
```

</details>

---

## Phi-4-mini Instruct Q8_0
Quantization: Q8_0 · Params: 3.8B (dense) · File: ~4 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 1416.7 ±275.2 | 50.2 ±0.5 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=1101.93 tg=50.68 (prompt=545 tok, gen=128 tok)
Run 2: pp=1611.43 tg=50.05 (prompt=545 tok, gen=128 tok)
Run 3: pp=1536.83 tg=49.77 (prompt=545 tok, gen=128 tok)
```

</details>

---

## Qwen3-Coder-Next 80B Q6_K ‡
Quantization: Q6_K · Params: 80B total / 3B active (MoE) · File: ~66 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 40s | 318.9 ±26.3 | 38.1 ±0.3 | |
| ROCm 7.2 | 30s | 219.6 ±2.0 | 33.0 ±0.7 | flash-attn, q4_0 KV |
| CPU | 20s | 93.6 ±2.3 | 11.7 ±0.1 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=288.60 tg=37.82 (prompt=587 tok, gen=128 tok)
  Run 2: pp=336.48 tg=38.11 (prompt=587 tok, gen=128 tok)
  Run 3: pp=331.46 tg=38.45 (prompt=587 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=218.12 tg=33.76 (prompt=587 tok, gen=128 tok)
  Run 2: pp=218.88 tg=32.83 (prompt=587 tok, gen=128 tok)
  Run 3: pp=221.84 tg=32.36 (prompt=587 tok, gen=128 tok)
CPU:
  Run 1: pp=93.19 tg=11.80 (prompt=587 tok, gen=128 tok)
  Run 2: pp=91.56 tg=11.65 (prompt=587 tok, gen=128 tok)
  Run 3: pp=96.11 tg=11.61 (prompt=587 tok, gen=128 tok)
```

</details>

---

## MiniMax M2.5 REAP 172B Q4_K_M ‡
Quantization: Q4_K_M · Params: 172B total / 10B active (MoE) · File: ~97 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 1m30s | 133.9 ±5.5 | 28.0 ±0.6 | |
| ROCm 7.2 | 1m00s | 181.7 ±3.2 | 22.8 ±0.7 | flash-attn, q4_0 KV |
| CPU | 1m41s | 57.2 ±10.9 | 11.9 ±0.9 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=127.54 tg=27.34 (prompt=579 tok, gen=128 tok)
  Run 2: pp=137.47 tg=28.48 (prompt=579 tok, gen=128 tok)
  Run 3: pp=136.66 tg=28.16 (prompt=579 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=184.54 tg=23.47 (prompt=579 tok, gen=128 tok)
  Run 2: pp=182.23 tg=22.92 (prompt=579 tok, gen=128 tok)
  Run 3: pp=178.17 tg=22.07 (prompt=579 tok, gen=128 tok)
CPU:
  Run 1: pp=44.60 tg=12.52 (prompt=579 tok, gen=128 tok)
  Run 2: pp=63.81 tg=12.37 (prompt=579 tok, gen=128 tok)
  Run 3: pp=63.26 tg=10.86 (prompt=579 tok, gen=128 tok)
```

</details>

---

## DeepSeek R1-0528 Qwen3 8B Q8_0
Quantization: Q8_0 · Params: 8B (dense) · File: ~8 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 700.8 ±64.9 | 26.6 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=626.97 tg=26.59 (prompt=582 tok, gen=128 tok)
Run 2: pp=748.74 tg=26.55 (prompt=582 tok, gen=128 tok)
Run 3: pp=726.69 tg=26.51 (prompt=582 tok, gen=128 tok)
```

</details>

---

## MiniMax M2.5 REAP 139B MXFP4 ‡
Quantization: MXFP4 · Params: 139B total / 10B active (MoE) · File: ~71 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 40s | 183.5 ±6.0 | 25.4 ±0.4 | |
| ROCm 7.2 | 50s | 172.8 ±2.9 | 22.7 ±0.5 | flash-attn, q4_0 KV |
| CPU | 30s | 50.1 ±1.1 | 11.6 ±0.2 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=176.60 tg=25.04 (prompt=579 tok, gen=128 tok)
  Run 2: pp=187.26 tg=25.45 (prompt=579 tok, gen=128 tok)
  Run 3: pp=186.71 tg=25.80 (prompt=579 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=176.09 tg=23.21 (prompt=579 tok, gen=128 tok)
  Run 2: pp=171.02 tg=22.66 (prompt=579 tok, gen=128 tok)
  Run 3: pp=171.18 tg=22.22 (prompt=579 tok, gen=128 tok)
CPU:
  Run 1: pp=51.32 tg=11.88 (prompt=579 tok, gen=128 tok)
  Run 2: pp=49.63 tg=11.49 (prompt=579 tok, gen=128 tok)
  Run 3: pp=49.40 tg=11.39 (prompt=579 tok, gen=128 tok)
```

</details>

---

## Qwen3-235B-A22B Q2_K ‡
Quantization: Q2_K · Params: 235B total / 22B active (MoE) · File: ~86 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 1m01s | 98.5 ±2.7 | 19.6 ±0.1 | |
| ROCm 7.2 | 40s | 107.0 ±2.5 | 16.9 ±0.5 | flash-attn, q4_0 KV |
| CPU | 50s | 25.4 ±2.5 | 8.2 ±0.5 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=95.45 tg=19.70 (prompt=587 tok, gen=128 tok)
  Run 2: pp=100.45 tg=19.66 (prompt=587 tok, gen=128 tok)
  Run 3: pp=99.61 tg=19.47 (prompt=587 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=108.98 tg=17.36 (prompt=587 tok, gen=128 tok)
  Run 2: pp=107.85 tg=16.88 (prompt=587 tok, gen=128 tok)
  Run 3: pp=104.24 tg=16.40 (prompt=587 tok, gen=128 tok)
CPU:
  Run 1: pp=22.66 tg=8.75 (prompt=587 tok, gen=128 tok)
  Run 2: pp=27.71 tg=7.95 (prompt=587 tok, gen=128 tok)
  Run 3: pp=25.82 tg=7.79 (prompt=587 tok, gen=128 tok)
```

</details>

---

## Llama 4 Scout 17Bx16E UD-Q4_K_XL ‡
Quantization: UD-Q4_K_XL · Params: 109B total / 17B active (MoE) · File: ~62 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 31s | 126.5 ±8.0 | 18.7 ±0.8 | |
| ROCm 7.2 | 30s | 266.9 ±4.1 | 18.6 ±0.3 | flash-attn, q4_0 KV |
| CPU | 41s | 53.2 ±0.1 | 9.4 ±0.1 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=122.53 tg=19.16 (prompt=550 tok, gen=128 tok)
  Run 2: pp=121.19 tg=17.84 (prompt=550 tok, gen=128 tok)
  Run 3: pp=135.70 tg=19.21 (prompt=550 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=271.63 tg=18.98 (prompt=550 tok, gen=128 tok)
  Run 2: pp=264.97 tg=18.38 (prompt=550 tok, gen=128 tok)
  Run 3: pp=264.08 tg=18.54 (prompt=550 tok, gen=128 tok)
CPU:
  Run 1: pp=53.21 tg=9.39 (prompt=550 tok, gen=128 tok)
  Run 2: pp=53.13 tg=9.52 (prompt=550 tok, gen=128 tok)
  Run 3: pp=53.21 tg=9.36 (prompt=550 tok, gen=128 tok)
```

</details>

---

## Phi-4-reasoning-plus Q8_0
Quantization: Q8_0 · Params: 14B (dense) · File: ~16 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 467.4 ±5.2 | 14.5 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=461.58 tg=14.51 (prompt=555 tok, gen=128 tok)
Run 2: pp=471.45 tg=14.51 (prompt=552 tok, gen=128 tok)
Run 3: pp=469.17 tg=14.51 (prompt=552 tok, gen=128 tok)
```

</details>

---

## Mistral Small 3.1 24B Instruct Q5_K_M
Quantization: Q5_K_M · Params: 24B (dense) · File: ~17 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 250.8 ±2.2 | 13.2 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=251.68 tg=13.21 (prompt=593 tok, gen=128 tok)
Run 2: pp=252.50 tg=13.20 (prompt=590 tok, gen=128 tok)
Run 3: pp=248.26 tg=13.21 (prompt=590 tok, gen=128 tok)
```

</details>

---

## Qwen2.5-Coder 32B Instruct Q4_K_M
Quantization: Q4_K_M · Params: 32B (dense) · File: ~20 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 202.3 ±5.2 | 11.1 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=196.36 tg=11.07 (prompt=608 tok, gen=128 tok)
Run 2: pp=205.13 tg=11.09 (prompt=608 tok, gen=128 tok)
Run 3: pp=205.58 tg=11.06 (prompt=608 tok, gen=128 tok)
```

</details>

---

## Gemma 3 27B Instruct Q6_K *(vision)*
Quantization: Q6_K · Params: 27B (dense) · File: ~22 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 10s | 184.4 ±3.3 | 9.4 ±0.1 | text-only (no mmproj) |

<details><summary>Per-run detail</summary>

```
Run 1: pp=180.69 tg=9.41 (prompt=599 tok, gen=128 tok)
Run 2: pp=186.90 tg=9.39 (prompt=599 tok, gen=128 tok)
Run 3: pp=185.71 tg=9.32 (prompt=599 tok, gen=128 tok)
```

</details>

---

## Qwen2.5-VL 72B Instruct IQ4_XS *(vision)*
Quantization: IQ4_XS · Params: 72B (dense) · File: ~40 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 21s | 82.2 ±0.2 | 5.3 ±0.0 | text-only (no mmproj) |

<details><summary>Per-run detail</summary>

```
Run 1: pp=82.38 tg=5.24 (prompt=598 tok, gen=128 tok)
Run 2: pp=82.27 tg=5.28 (prompt=598 tok, gen=128 tok)
Run 3: pp=82.07 tg=5.27 (prompt=598 tok, gen=128 tok)
```

</details>

---

## DeepSeek R1 Distill Llama 70B Q4_K_M ‡
Quantization: Q4_K_M · Params: 70B (dense) · File: ~43 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 20s | 75.4 ±1.9 | 5.0 ±0.0 | |
| ROCm 7.2 | 20s | 119.5 ±2.3 | 4.9 ±0.0 | flash-attn, q4_0 KV |
| CPU | 31s | 17.1 ±0.3 | 2.3 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=73.21 tg=5.04 (prompt=550 tok, gen=128 tok)
  Run 2: pp=76.75 tg=5.05 (prompt=550 tok, gen=128 tok)
  Run 3: pp=76.31 tg=5.06 (prompt=550 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=117.69 tg=4.90 (prompt=550 tok, gen=128 tok)
  Run 2: pp=122.11 tg=4.88 (prompt=550 tok, gen=128 tok)
  Run 3: pp=118.58 tg=4.83 (prompt=550 tok, gen=128 tok)
CPU:
  Run 1: pp=16.81 tg=2.30 (prompt=550 tok, gen=128 tok)
  Run 2: pp=17.04 tg=2.34 (prompt=550 tok, gen=128 tok)
  Run 3: pp=17.35 tg=2.34 (prompt=550 tok, gen=128 tok)
```

</details>

---

## Command-A 111B IQ4_XS
Quantization: IQ4_XS · Params: 111B total / ~14B active (MoE) · File: ~60 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 30s | 36.8 ±0.0 | 3.4 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=36.82 tg=3.37 (prompt=597 tok, gen=128 tok)
Run 2: pp=36.76 tg=3.37 (prompt=594 tok, gen=128 tok)
Run 3: pp=36.74 tg=3.37 (prompt=594 tok, gen=128 tok)
```

</details>

---

## Llama 3.3 70B Instruct Q8_0 ‡
Quantization: Q8_0 · Params: 70B (dense) · File: ~75 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 50s | 82.4 ±0.5 | 3.0 ±0.0 | |
| ROCm 7.2 | 40s | 107.1 ±2.1 | 2.9 ±0.0 | flash-attn, q4_0 KV |
| CPU | 30s | 13.2 ±0.0 | 1.4 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=81.87 tg=2.95 (prompt=590 tok, gen=128 tok)
  Run 2: pp=82.87 tg=2.97 (prompt=590 tok, gen=128 tok)
  Run 3: pp=82.55 tg=2.97 (prompt=590 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=109.42 tg=2.93 (prompt=590 tok, gen=128 tok)
  Run 2: pp=106.30 tg=2.95 (prompt=590 tok, gen=128 tok)
  Run 3: pp=105.49 tg=2.94 (prompt=590 tok, gen=128 tok)
CPU:
  Run 1: pp=13.17 tg=1.36 (prompt=590 tok, gen=128 tok)
  Run 2: pp=13.19 tg=1.36 (prompt=590 tok, gen=128 tok)
  Run 3: pp=13.18 tg=1.36 (prompt=590 tok, gen=128 tok)
```

</details>

---

## Qwen2.5 72B Instruct Q8_0 ‡
Quantization: Q8_0 · Params: 72B (dense) · File: ~77 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 1m40s | 60.4 ±0.6 | 2.9 ±0.0 | |
| ROCm 7.2 | 40s | 123.1 ±3.3 | 2.9 ±0.0 | flash-attn, q4_0 KV |
| CPU | 30s | 12.3 ±0.4 | 1.3 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=59.78 tg=2.86 (prompt=608 tok, gen=128 tok)
  Run 2: pp=60.84 tg=2.89 (prompt=608 tok, gen=128 tok)
  Run 3: pp=60.56 tg=2.89 (prompt=608 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=126.40 tg=2.87 (prompt=608 tok, gen=128 tok)
  Run 2: pp=122.99 tg=2.86 (prompt=608 tok, gen=128 tok)
  Run 3: pp=119.79 tg=2.85 (prompt=608 tok, gen=128 tok)
CPU:
  Run 1: pp=12.01 tg=1.28 (prompt=608 tok, gen=128 tok)
  Run 2: pp=12.20 tg=1.32 (prompt=608 tok, gen=128 tok)
  Run 3: pp=12.81 tg=1.32 (prompt=608 tok, gen=128 tok)
```

</details>

---

## Devstral-2 123B Q5_K_M ‡
Quantization: Q5_K_M · Params: 123B (dense) · File: ~88 GiB

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | 1m01s | 39.3 ±0.8 | 2.5 ±0.0 | |
| ROCm 7.2 | 50s | 67.5 ±1.6 | 2.4 ±0.0 | flash-attn, q4_0 KV |
| CPU | 30s | 4.3 ±0.0 | 1.1 ±0.0 | no GPU offload |

<details><summary>Per-run detail</summary>

```
Vulkan:
  Run 1: pp=38.37 tg=2.43 (prompt=595 tok, gen=128 tok)
  Run 2: pp=39.74 tg=2.48 (prompt=595 tok, gen=128 tok)
  Run 3: pp=39.73 tg=2.48 (prompt=595 tok, gen=128 tok)
ROCm 7.2:
  Run 1: pp=65.89 tg=2.40 (prompt=595 tok, gen=128 tok)
  Run 2: pp=69.00 tg=2.37 (prompt=595 tok, gen=128 tok)
  Run 3: pp=67.77 tg=2.41 (prompt=595 tok, gen=128 tok)
CPU:
  Run 1: pp=4.32 tg=1.14 (prompt=595 tok, gen=128 tok)
  Run 2: pp=4.31 tg=1.13 (prompt=595 tok, gen=128 tok)
  Run 3: pp=4.31 tg=1.12 (prompt=595 tok, gen=128 tok)
```

</details>
