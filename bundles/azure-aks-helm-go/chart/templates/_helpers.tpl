{{- define "app.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $k, $v := .Values.md_metadata.default_tags }}
{{ $k | replace ":" "-" | replace "/" "-" | trunc 63 }}: {{ $v | toString | replace ":" "-" | replace "/" "-" | trunc 63 | quote }}
{{- end }}
{{- end -}}

{{- define "app.selector" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end -}}
