{{/*
Get backend configuration
*/}}
{{- define "inference-model.backend" -}}
{{- $backendName := .Values.backend | default "llamacpp-vulkan" -}}
{{- index .Values.backends $backendName | default (index .Values.backends "llamacpp-vulkan") -}}
{{- end -}}

{{/*
Get image for backend
*/}}
{{- define "inference-model.image" -}}
{{- $backend := include "inference-model.backend" . | fromYaml -}}
{{- printf "%s:%s" $backend.image.repository $backend.image.tag -}}
{{- end -}}

{{/*
Get port for backend
*/}}
{{- define "inference-model.port" -}}
{{- $backend := include "inference-model.backend" . | fromYaml -}}
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
