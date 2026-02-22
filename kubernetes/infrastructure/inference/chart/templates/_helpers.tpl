{{/*
Get backend name
*/}}
{{- define "inference-model.backendName" -}}
{{- .Values.backend | default "llamacpp-vulkan" -}}
{{- end -}}

{{/*
Get backend configuration (returns dict)
*/}}
{{- define "inference-model.backend" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- $backends := .Values.backends | default dict -}}
{{- $defaultBackend := index $backends "llamacpp-vulkan" | default dict -}}
{{- index $backends $backendName | default $defaultBackend -}}
{{- end -}}

{{/*
Get image for backend
*/}}
{{- define "inference-model.image" -}}
{{- $backend := include "inference-model.backend" . -}}
{{- $image := index $backend "image" | default dict -}}
{{- $repo := index $image "repository" | default "ghcr.io/ggml-org/llama.cpp" -}}
{{- $tag := index $image "tag" | default "server-vulkan" -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}

{{/*
Get port for backend
*/}}
{{- define "inference-model.port" -}}
{{- $backend := include "inference-model.backend" . -}}
{{- .Values.service.port | default (index $backend "port") | default 8080 -}}
{{- end -}}

{{/*
Model labels
*/}}
{{- define "inference-model.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: inference
app.kubernetes.io/managed-by: flux
{{- end -}}
