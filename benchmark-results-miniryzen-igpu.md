# Inference Benchmark Results — miniryzen iGPU

**Hardware:** AMD Barcelo — Radeon 610M (gfx909), 15 GB shared VRAM (unified system memory)
**Node:** miniryzen (7 CUs @ 2.0 GHz, Ryzen 5 5500U)
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; context per model
**Prompt:** ~186 tokens (infrastructure scenario; nonce system message added per run to bust KV cache)
**Backend:** llamacpp-vulkan image, n_gpu_layers=0 (CPU inference — GPU layers not set in llamacpp-vulkan backend)
**Method:** Direct port-forward to pod (`kubectl port-forward svc/<name> 18765:8080`), bypassing LiteLLM/Cloudflare
**Measurement:** PP and TG from llama.cpp's internal `/v1/chat/completions` timings (accurate; `/completion` endpoint reports 1e6 tok/s TG due to Vulkan timer bug on gfx909)

**PP** = prompt processing speed (tok/s)
**TG** = token generation speed (tok/s)

---

## Summary

Sorted by TG speed descending. ‡ = also benchmarked on shadow (see benchmark-results.md for comparison).

| Model | Quant | Params | Context | PP | TG |
|-------|-------|--------|---------|----|----|
| SmolLM2 1.7B Instruct | Q8_0 | 1.7B | 4096 | 89.9 ±2.6 | 8.9 ±0.3 |
| Llama 3.2 3B Instruct | Q8_0 | 3B | 8192 | 53.0 ±0.7 | 5.2 ±0.0 |
| Phi-4-mini Instruct ‡ | Q8_0 | 3.8B | 16384 | 45.8 ±0.9 | 4.4 ±0.0 |
| Qwen2.5 7B Instruct | Q8_0 | 7B | 16384 | 22.7 ±0.5 | 2.4 ±0.0 |
| DeepSeek R1-0528 Qwen3 8B ‡ | Q8_0 | 8B | 16384 | 20.9 ±0.0 | 2.2 ±0.0 |

---

## Detail

---

## SmolLM2 1.7B Instruct Q8_0
Quantization: Q8_0 · Params: 1.7B (dense) · File: ~1.8 GiB · Context: 4096

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| CPU (Vulkan image, n_gpu_layers=0) | 89.9 ±2.6 | 8.9 ±0.3 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=92.5 tg=9.2 (prompt=212 tok, gen=128 tok, ttft=2.29s)
Run 2: pp=87.3 tg=8.9 (prompt=213 tok, gen=128 tok, ttft=2.44s)
Run 3: pp=89.8 tg=8.7 (prompt=212 tok, gen=128 tok, ttft=2.36s)
```

</details>

---

## Llama 3.2 3B Instruct Q8_0
Quantization: Q8_0 · Params: 3B (dense) · File: ~3.2 GiB · Context: 8192

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| CPU (Vulkan image, n_gpu_layers=0) | 53.0 ±0.7 | 5.2 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=53.8 tg=5.2 (prompt=178 tok, gen=128 tok, ttft=3.31s)
Run 2: pp=52.5 tg=5.3 (prompt=179 tok, gen=128 tok, ttft=3.41s)
Run 3: pp=52.7 tg=5.2 (prompt=179 tok, gen=128 tok, ttft=3.40s)
```

</details>

---

## Phi-4-mini Instruct Q8_0 ‡
Quantization: Q8_0 · Params: 3.8B (dense) · File: ~4 GiB · Context: 16384
Shadow result: PP=1417 ±275 tok/s, TG=50.2 ±0.5 tok/s (Vulkan, gfx1151)

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| CPU (Vulkan image, n_gpu_layers=0) | 45.8 ±0.9 | 4.4 ±0.0 | Context reduced from 131072→16384 to fit 10Gi memory limit |

<details><summary>Per-run detail</summary>

```
Run 1: pp=46.6 tg=4.4 (prompt=172 tok, gen=128 tok, ttft=3.69s)
Run 2: pp=44.9 tg=4.4 (prompt=171 tok, gen=128 tok, ttft=3.81s)
Run 3: pp=46.0 tg=4.4 (prompt=171 tok, gen=128 tok, ttft=3.72s)
```

</details>

---

## Qwen2.5 7B Instruct Q8_0
Quantization: Q8_0 · Params: 7B (dense) · File: ~7.6 GiB · Context: 16384

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| CPU (Vulkan image, n_gpu_layers=0) | 22.7 ±0.5 | 2.4 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=23.3 tg=2.4 (prompt=200 tok, gen=128 tok, ttft=8.59s)
Run 2: pp=22.2 tg=2.4 (prompt=199 tok, gen=128 tok, ttft=8.95s)
Run 3: pp=22.6 tg=2.4 (prompt=199 tok, gen=128 tok, ttft=8.80s)
```

</details>

---

## DeepSeek R1-0528 Qwen3 8B Q8_0 ‡
Quantization: Q8_0 · Params: 8B (dense) · File: ~8 GiB · Context: 16384
Shadow result: PP=701 ±65 tok/s, TG=26.6 ±0.0 tok/s (Vulkan, gfx1151)

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| CPU (Vulkan image, n_gpu_layers=0) | 20.9 ±0.0 | 2.2 ±0.0 | |

<details><summary>Per-run detail</summary>

```
Run 1: pp=20.8 tg=2.3 (prompt=187 tok, gen=128 tok, ttft=8.98s)
Run 2: pp=20.8 tg=2.2 (prompt=189 tok, gen=128 tok, ttft=9.07s)
Run 3: pp=20.9 tg=2.2 (prompt=189 tok, gen=128 tok, ttft=9.05s)
```

</details>
