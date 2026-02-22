{{/*
Get backend name
*/}}
{{- define "inference-model.backendName" -}}
{{- .Values.backend | default "llamacpp-vulkan" -}}
{{- end -}}

{{/*
Get backend configuration as JSON string
*/}}
{{- define "inference-model.backendJson" -}}
{{- $backendName := include "inference-model.backendName" . -}}
{{- $backends := .Values.backends | default dict -}}
{{- $defaultBackend := index $backends "llamacpp-vulkan" | default dict -}}
{{- $backend := index $backends $backendName | default $defaultBackend -}}
{{- $backend | toJson -}}
{{- end -}}

{{/*
Get image for backend
*/}}
{{- define "inference-model.image" -}}
{{- $backend := include "inference-model.backendJson" . | fromJson -}}
{{- $image := dict "repository" "ghcr.io/ggml-org/llama.cpp" "tag" "server-vulkan" -}}
{{- if $backend.image -}}
{{- $image = $backend.image -}}
{{- end -}}
{{- printf "%s:%s" $image.repository $image.tag -}}
{{- end -}}

{{/*
Get port for backend
*/}}
{{- define "inference-model.port" -}}
{{- $backend := include "inference-model.backendJson" . | fromJson -}}
{{- .Values.service.port | default $backend.port | default 8080 -}}
{{- end -}}

{{/*
Model labels
*/}}
{{- define "inference-model.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: inference
app.kubernetes.io/managed-by: flux
{{- end -}}
