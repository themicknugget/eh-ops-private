# Inference Benchmark Results — miniryzen iGPU

**Hardware:** AMD Barcelo — Radeon 610M (gfx909), 15 GB shared VRAM (unified system memory)
**Node:** miniryzen (7 CUs @ 2.0 GHz, Ryzen 5 5500U)
**Benchmark:** 3-run average after 1 warmup; 128 max generated tokens; context per model
**Prompt:** ~600 tokens (infrastructure scenario)
**Vulkan:** Mesa RADV (gfx9), llamacpp-vulkan, LLAMA_HIP_UMA=ON, mmap

**PP** = prompt processing speed (tok/s)
**TG** = token generation speed (tok/s)
**Load** = server startup + model load time

---

## Summary

Sorted by TG speed descending. ‡ = also benchmarked on shadow (see benchmark-results.md for comparison).

| Model | Quant | Params | Context | Load | PP | TG |
|-------|-------|--------|---------|------|----|----|
| SmolLM2 1.7B Instruct | Q8_0 | 1.7B | 4096 | | | |
| Llama 3.2 3B Instruct | Q8_0 | 3B | 8192 | | | |
| Phi-4-mini Instruct ‡ | Q8_0 | 3.8B | 4096 | | | |
| Qwen2.5 7B Instruct | Q8_0 | 7B | 16384 | | | |
| DeepSeek R1-0528 Qwen3 8B ‡ | Q8_0 | 8B | 16384 | | | |

---

## Detail

---

## SmolLM2 1.7B Instruct Q8_0
Quantization: Q8_0 · Params: 1.7B (dense) · File: ~1.8 GiB · Context: 4096

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | | | | |

<details><summary>Per-run detail</summary>

```
Run 1: pp= tg= (prompt= tok, gen=128 tok)
Run 2: pp= tg= (prompt= tok, gen=128 tok)
Run 3: pp= tg= (prompt= tok, gen=128 tok)
```

</details>

---

## Llama 3.2 3B Instruct Q8_0
Quantization: Q8_0 · Params: 3B (dense) · File: ~3.2 GiB · Context: 8192

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | | | | |

<details><summary>Per-run detail</summary>

```
Run 1: pp= tg= (prompt= tok, gen=128 tok)
Run 2: pp= tg= (prompt= tok, gen=128 tok)
Run 3: pp= tg= (prompt= tok, gen=128 tok)
```

</details>

---

## Phi-4-mini Instruct Q8_0 ‡
Quantization: Q8_0 · Params: 3.8B (dense) · File: ~4 GiB · Context: 4096
Shadow result: PP=1417 ±275 tok/s, TG=50.2 ±0.5 tok/s (Vulkan, gfx1151)

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | | | | |

<details><summary>Per-run detail</summary>

```
Run 1: pp= tg= (prompt= tok, gen=128 tok)
Run 2: pp= tg= (prompt= tok, gen=128 tok)
Run 3: pp= tg= (prompt= tok, gen=128 tok)
```

</details>

---

## Qwen2.5 7B Instruct Q8_0
Quantization: Q8_0 · Params: 7B (dense) · File: ~7.6 GiB · Context: 16384

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | | | | |

<details><summary>Per-run detail</summary>

```
Run 1: pp= tg= (prompt= tok, gen=128 tok)
Run 2: pp= tg= (prompt= tok, gen=128 tok)
Run 3: pp= tg= (prompt= tok, gen=128 tok)
```

</details>

---

## DeepSeek R1-0528 Qwen3 8B Q8_0 ‡
Quantization: Q8_0 · Params: 8B (dense) · File: ~8 GiB · Context: 16384
Shadow result: PP=701 ±65 tok/s, TG=26.6 ±0.0 tok/s (Vulkan, gfx1151)

| Backend | Load | PP (tok/s) | TG (tok/s) | Notes |
|---------|------|-----------|-----------|-------|
| Vulkan | | | | |

<details><summary>Per-run detail</summary>

```
Run 1: pp= tg= (prompt= tok, gen=128 tok)
Run 2: pp= tg= (prompt= tok, gen=128 tok)
Run 3: pp= tg= (prompt= tok, gen=128 tok)
```

</details>
