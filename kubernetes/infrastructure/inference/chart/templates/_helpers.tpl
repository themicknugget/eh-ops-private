{{/*
Get backend name
*/}}
{{- define "inference-model.backendName" -}}
{{- .Values.backend | default "llamacpp-vulkan" -}}
{{- end -}}

{{/*
Get image for model
Checks: 1. values.image  2. backend-specific defaults
*/}}
{{- define "inference-model.image" -}}
{{- $repo := .Values.image.repository | default "" -}}
{{- $tag := .Values.image.tag | default "" -}}
{{- if not $repo -}}
{{- /* Default images per backend */ -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if eq $backendName "llamacpp-vulkan" -}}
{{- $repo = "ghcr.io/ggml-org/llama.cpp" -}}
{{- $tag = "server-vulkan" -}}
{{- else if eq $backendName "llamacpp-vulkan-moe" -}}
{{- $repo = "ghcr.io/ggml-org/llama.cpp" -}}
{{- $tag = "server-vulkan" -}}
{{- else if eq $backendName "llamacpp-rocm" -}}
{{- $repo = "docker.io/kyuz0/amd-strix-halo-toolboxes" -}}
{{- $tag = "rocm-7.2" -}}
{{- else if eq $backendName "llamacpp-cpu" -}}
{{- $repo = "ghcr.io/ggml-org/llama.cpp" -}}
{{- $tag = "server" -}}
{{- else if eq $backendName "vllm" -}}
{{- $repo = "vllm/vllm-openai" -}}
{{- $tag = "latest" -}}
{{- else if eq $backendName "whisper-cpp" -}}
{{- $repo = "ghcr.io/ggml-org/whisper.cpp" -}}
{{- $tag = "main" -}}
{{- else -}}
{{- $repo = "ghcr.io/ggml-org/llama.cpp" -}}
{{- $tag = "server-vulkan" -}}
{{- end -}}
{{- end -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Get backend entrypoint command (empty = use image default ENTRYPOINT)
Required for toolbox-style images that default to /bin/bash
*/}}
{{- define "inference-model.backendCommand" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if eq $backendName "llamacpp-rocm" -}}
- /usr/local/bin/llama-server
{{- else if eq $backendName "whisper-cpp" -}}
- /app/build/bin/whisper-server
{{- end -}}
{{- end -}}

{{/*
Get port for model
*/}}
{{- define "inference-model.port" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- $port := .Values.service.port | default 8080 -}}
{{- if eq $backendName "vllm" -}}
{{- $port = .Values.service.port | default 8000 -}}
{{- end -}}
{{- $port -}}
{{- end -}}

{{/*
Get backend env vars
*/}}
{{- define "inference-model.backendEnv" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if eq $backendName "llamacpp-vulkan" -}}
- name: LLAMA_HIP_UMA
  value: "ON"
{{- else if eq $backendName "llamacpp-vulkan-moe" -}}
- name: LLAMA_HIP_UMA
  value: "ON"
- name: LLAMA_ARG_N_GPU_LAYERS
  value: "99"
- name: LLAMA_ARG_FLASH_ATTN
  value: "1"
- name: LLAMA_ARG_CACHE_TYPE_K
  value: "q4_0"
- name: LLAMA_ARG_CACHE_TYPE_V
  value: "q4_0"
- name: LLAMA_ARG_THREADS
  value: "12"
- name: LLAMA_ARG_BATCH_SIZE
  value: "4096"
- name: LLAMA_ARG_UBATCH_SIZE
  value: "1024"
- name: LLAMA_ARG_ENDPOINT_METRICS
  value: "1"
{{- else if eq $backendName "llamacpp-rocm" -}}
- name: ROCBLAS_USE_HIPBLASLT
  value: "1"
- name: HSA_ENABLE_SDMA
  value: "0"
- name: GPU_MAX_HW_QUEUES
  value: "1"
- name: LLAMA_ARG_N_GPU_LAYERS
  value: "99"
- name: LLAMA_ARG_FLASH_ATTN
  value: "1"
- name: LLAMA_ARG_CACHE_TYPE_K
  value: "q4_0"
- name: LLAMA_ARG_CACHE_TYPE_V
  value: "q4_0"
- name: LLAMA_ARG_THREADS
  value: "12"
- name: LLAMA_ARG_BATCH_SIZE
  value: "4096"
- name: LLAMA_ARG_UBATCH_SIZE
  value: "1024"
- name: LLAMA_ARG_ENDPOINT_METRICS
  value: "1"
{{- end -}}
{{- end -}}

{{/*
Get backend args as YAML list
*/}}
{{- define "inference-model.backendArgs" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if or (eq $backendName "llamacpp-vulkan") (eq $backendName "llamacpp-vulkan-moe") -}}
- -m
- $(HF_SOURCE)
{{- if .Values.storage.mmprojFile }}
- --mmproj
- $(MMPROJ_SOURCE)
{{- end }}
- --host
- 0.0.0.0
- --port
- "8080"
- --metrics
{{- else if eq $backendName "llamacpp-rocm" -}}
- -m
- $(HF_SOURCE)
{{- if .Values.storage.mmprojFile }}
- --mmproj
- $(MMPROJ_SOURCE)
{{- end }}
- --host
- 0.0.0.0
- --port
- "8080"
- --metrics
- --no-mmap
{{- else if eq $backendName "llamacpp-cpu" -}}
- -m
- $(HF_SOURCE)
- --host
- 0.0.0.0
- --port
- "8080"
- --metrics
- -c
- "8192"
{{- else if eq $backendName "vllm" -}}
- --model
- $(HF_SOURCE)
- --host
- 0.0.0.0
- --port
- "8000"
{{- else if eq $backendName "whisper-cpp" -}}
- -m
- $(HF_SOURCE)
- --host
- 0.0.0.0
- --port
- "8080"
{{- end -}}
{{- end -}}

{{/*
Get backend security context
*/}}
{{- define "inference-model.securityContext" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if or (eq $backendName "llamacpp-vulkan") (eq $backendName "llamacpp-vulkan-moe") (eq $backendName "llamacpp-rocm") -}}
capabilities:
  add: [SYS_PTRACE]
seccompProfile:
  type: Unconfined
{{- end -}}
{{- end -}}

{{/*
Get backend volumes
*/}}
{{- define "inference-model.volumes" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if or (eq $backendName "llamacpp-vulkan") (eq $backendName "llamacpp-vulkan-moe") (eq $backendName "llamacpp-rocm") -}}
- name: dri
  hostPath:
    path: /dev/dri
- name: kfd
  hostPath:
    path: /dev/kfd
{{- end -}}
{{- end -}}

{{/*
Get backend volume mounts
*/}}
{{- define "inference-model.volumeMounts" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if or (eq $backendName "llamacpp-vulkan") (eq $backendName "llamacpp-vulkan-moe") (eq $backendName "llamacpp-rocm") -}}
- mountPath: /dev/dri
  name: dri
- mountPath: /dev/kfd
  name: kfd
{{- end -}}
{{- end -}}

{{/*
Get backend readiness path
*/}}
{{- define "inference-model.readinessPath" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- if eq $backendName "whisper-cpp" -}}
/
{{- else -}}
/health
{{- end -}}
{{- end -}}

{{/*
Model labels
*/}}
{{- define "inference-model.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: inference
app.kubernetes.io/managed-by: flux
{{- end -}}
