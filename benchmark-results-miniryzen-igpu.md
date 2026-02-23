# Inference Benchmark Results — miniryzen iGPU

**Hardware:** AMD Barcelo — Radeon 610M (gfx909), 15 GB shared VRAM (unified system memory)
**Node:** miniryzen (7 CUs @ 2.0 GHz, Ryzen 5 5500U)
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; context per model
**Prompt:** ~186 tokens (infrastructure scenario; nonce system message added per run to bust KV cache)
**Backend:** llamacpp-vulkan image, n_gpu_layers=99 (all layers offloaded to Vulkan iGPU)
**Method:** Direct port-forward to pod (`kubectl port-forward svc/<name> 18765:8080`), bypassing LiteLLM/Cloudflare
**Measurement:** PP and TG from llama.cpp's internal `/v1/chat/completions` timings (accurate; `/completion` endpoint reports 1e6 tok/s TG due to Vulkan timer bug on gfx909)

**PP** = prompt processing speed (tok/s)
**TG** = token generation speed (tok/s)

---

## Summary

Sorted by TG speed descending. ‡ = also benchmarked on shadow (see benchmark-results.md for comparison).

| Model | Quant | Params | Context | PP | TG |
|-------|-------|--------|---------|----|-----|
| SmolLM2 1.7B Instruct | Q8_0 | 1.7B | 4096 | 215.8 ±10.6 | 9.7 ±0.0 |
| Llama 3.2 3B Instruct | Q8_0 | 3B | 8192 | 134.9 ±1.2 | 5.3 ±0.0 |
| Phi-4-mini Instruct ‡ | Q8_0 | 3.8B | 16384 | 110.9 ±3.1 | 4.4 ±0.0 |
| Qwen2.5 7B Instruct | Q8_0 | 7B | 16384 | 48.3 ±0.9 | 2.5 ±0.0 |
| DeepSeek R1-0528 Qwen3 8B ‡ | Q8_0 | 8B | 16384 | 53.0 ±1.1 | 2.3 ±0.0 |

---

## Detail

---

## SmolLM2 1.7B Instruct Q8_0
Quantization: Q8_0 · Params: 1.7B (dense) · File: ~1.8 GiB · Context: 4096

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| Vulkan iGPU (gfx909, 7 CU) | 215.8 ±10.6 | 9.7 ±0.0 | All 25 layers offloaded |
| CPU (n_gpu_layers=0) | 89.9 ±2.6 | 8.9 ±0.3 | |

<details><summary>Per-run detail (Vulkan)</summary>

```
Run 1: pp=224.9 tg=9.8 (prompt=213 tok, gen=128 tok, ttft=0.95s)
Run 2: pp=204.2 tg=9.7 (prompt=212 tok, gen=128 tok, ttft=1.04s)
Run 3: pp=218.4 tg=9.7 (prompt=212 tok, gen=128 tok, ttft=0.97s)
```

</details>

---

## Llama 3.2 3B Instruct Q8_0
Quantization: Q8_0 · Params: 3B (dense) · File: ~3.2 GiB · Context: 8192

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| Vulkan iGPU (gfx909, 7 CU) | 134.9 ±1.2 | 5.3 ±0.0 | All layers offloaded |
| CPU (n_gpu_layers=0) | 53.0 ±0.7 | 5.2 ±0.0 | |

<details><summary>Per-run detail (Vulkan)</summary>

```
Run 1: pp=133.5 tg=5.4 (prompt=178 tok, gen=128 tok, ttft=1.33s)
Run 2: pp=135.7 tg=5.3 (prompt=179 tok, gen=128 tok, ttft=1.32s)
Run 3: pp=135.5 tg=5.3 (prompt=179 tok, gen=128 tok, ttft=1.32s)
```

</details>

---

## Phi-4-mini Instruct Q8_0 ‡
Quantization: Q8_0 · Params: 3.8B (dense) · File: ~4 GiB · Context: 16384
Shadow result: PP=1417 ±275 tok/s, TG=50.2 ±0.5 tok/s (Vulkan, gfx1151)

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| Vulkan iGPU (gfx909, 7 CU) | 110.9 ±3.1 | 4.4 ±0.0 | Context reduced from 131072→16384 to fit 10Gi memory limit |
| CPU (n_gpu_layers=0) | 45.8 ±0.9 | 4.4 ±0.0 | Context reduced from 131072→16384 to fit 10Gi memory limit |

<details><summary>Per-run detail (Vulkan)</summary>

```
Run 1: pp=112.5 tg=4.5 (prompt=171 tok, gen=128 tok, ttft=1.52s)
Run 2: pp=112.9 tg=4.4 (prompt=171 tok, gen=128 tok, ttft=1.51s)
Run 3: pp=107.4 tg=4.4 (prompt=172 tok, gen=128 tok, ttft=1.60s)
```

</details>

---

## Qwen2.5 7B Instruct Q8_0
Quantization: Q8_0 · Params: 7B (dense) · File: ~7.6 GiB · Context: 16384

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| Vulkan iGPU (gfx909, 7 CU) | 48.3 ±0.9 | 2.5 ±0.0 | All layers offloaded |
| CPU (n_gpu_layers=0) | 22.7 ±0.5 | 2.4 ±0.0 | |

<details><summary>Per-run detail (Vulkan)</summary>

```
Run 1: pp=48.6 tg=2.5 (prompt=198 tok, gen=128 tok, ttft=4.08s)
Run 2: pp=47.3 tg=2.5 (prompt=200 tok, gen=128 tok, ttft=4.23s)
Run 3: pp=49.0 tg=2.5 (prompt=200 tok, gen=128 tok, ttft=4.08s)
```

</details>

---

## DeepSeek R1-0528 Qwen3 8B Q8_0 ‡
Quantization: Q8_0 · Params: 8B (dense) · File: ~8 GiB · Context: 16384
Shadow result: PP=701 ±65 tok/s, TG=26.6 ±0.0 tok/s (Vulkan, gfx1151)

| Backend | PP (tok/s) | TG (tok/s) | Notes |
|---------|-----------|-----------|-------|
| Vulkan iGPU (gfx909, 7 CU) | 53.0 ±1.1 | 2.3 ±0.0 | All layers offloaded |
| CPU (n_gpu_layers=0) | 20.9 ±0.0 | 2.2 ±0.0 | |

<details><summary>Per-run detail (Vulkan)</summary>

```
Run 1: pp=53.6 tg=2.3 (prompt=189 tok, gen=128 tok, ttft=3.53s)
Run 2: pp=51.8 tg=2.3 (prompt=190 tok, gen=128 tok, ttft=3.67s)
Run 3: pp=53.6 tg=2.3 (prompt=190 tok, gen=128 tok, ttft=3.54s)
```

</details>
