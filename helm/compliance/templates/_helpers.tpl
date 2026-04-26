{{/*
Common name helpers
*/}}
{{- define "compliance.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "compliance.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "compliance.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource
*/}}
{{- define "compliance.labels" -}}
helm.sh/chart: {{ include "compliance.chart" . }}
{{ include "compliance.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.environment | quote }}
{{- end }}

{{- define "compliance.selectorLabels" -}}
app.kubernetes.io/name: {{ include "compliance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "compliance.apiImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}/{{ .Values.image.api.name }}:{{ .Values.image.api.tag }}
{{- end }}

{{- define "compliance.frontendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}/{{ .Values.image.frontend.name }}:{{ .Values.image.frontend.tag }}
{{- end }}
