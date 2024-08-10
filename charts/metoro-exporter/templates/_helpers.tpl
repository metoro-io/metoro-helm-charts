{{/*
Expand the name of the chart.
*/}}
{{- define "metoro.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metoro.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "metoro.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metoro.labels" -}}
helm.sh/chart: {{ include "metoro.chart" . }}
{{ include "metoro.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metoro.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metoro.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metoro.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metoro.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Return the name of cert-manager's Certificate resources for webhooks.
*/}}
{{- define "metoro.webhookCertName" -}}
{{ template "metoro.fullname" . }}-serving-cert
{{- end }}

{{/*
Return the name of the cert-manager.io/inject-ca-from annotation for webhooks and CRDs.
*/}}
{{- define "metoro.webhookCertAnnotation" -}}
{{- if not .Values.instrumentationWebhook.mutatingWebhookConfiguration.certManager.enabled }}
{{- "none" }}
{{- else }}
{{- printf "%s/%s" .Release.Namespace (include "metoro.webhookCertName" .) }}
{{- end }}
{{- end }}

{{- define "metoro.MutatingWebhookName" -}}
{{- printf "%s-%s" (.Values.instrumentationWebhook.name | toString) (include "metoro.fullname" .) | trimPrefix "-" }}
{{- end }}

{{/*
Return certificate and CA for Webhooks.
It handles variants when a cert has to be generated by Helm,
a cert is loaded from an existing secret or is provided via `.Values`
*/}}
{{- define "metoro.WebhookCert" -}}
{{- $caCertEnc := "" }}
{{- $certCrtEnc := "" }}
{{- $certKeyEnc := "" }}
{{- if .Values.instrumentationWebhook.mutatingWebhookConfiguration.autoGenerateCert.enabled }}
{{- $prevSecret := (lookup "v1" "Secret" .Release.Namespace (default (printf "%s-mutating-webhook-service-cert" (include "metoro.fullname" .)) .Values.instrumentationWebhook.secretName )) }}
{{- if and (not .Values.instrumentationWebhook.mutatingWebhookConfiguration.autoGenerateCert.recreate) $prevSecret }}
{{- $certCrtEnc = index $prevSecret "data" "tls.crt" }}
{{- $certKeyEnc = index $prevSecret "data" "tls.key" }}
{{- $caCertEnc = index $prevSecret "data" "ca.crt" }}
{{- if not $caCertEnc }}
{{- $prevHook := (lookup "admissionregistration.k8s.io/v1" "MutatingWebhookConfiguration" .Release.Namespace (print (include "metoro.MutatingWebhookName" . ) "-mutation")) }}
{{- if not (eq (toString $prevHook) "<nil>") }}
{{- $caCertEnc = (first $prevHook.webhooks).clientConfig.caBundle }}
{{- end }}
{{- end }}
{{- else }}
{{- $altNames := list ( printf "%s.%s.svc" "metoro-instrumentation-webhook" .Release.Namespace ) ( printf "%s.%s.svc.cluster.local" "metoro-instrumentation-webhook" .Release.Namespace ) -}}
{{- $tmpperioddays := int .Values.instrumentationWebhook.mutatingWebhookConfiguration.autoGenerateCert.certPeriodDays | default 365 }}
{{- $ca := genCA "metoro-ca" $tmpperioddays }}
{{- $cert := genSignedCert "metoro-instrumentation-webhook.metoro.svc" nil $altNames $tmpperioddays $ca }}
{{- $certCrtEnc = b64enc $cert.Cert }}
{{- $certKeyEnc = b64enc $cert.Key }}
{{- $caCertEnc = b64enc $ca.Cert }}
{{- end }}
{{- else }}
{{- $certCrtEnc = .Files.Get .Values.admissionWebhooks.certFile | b64enc }}
{{- $certKeyEnc = .Files.Get .Values.admissionWebhooks.keyFile | b64enc }}
{{- $caCertEnc = .Files.Get .Values.admissionWebhooks.caFile | b64enc }}
{{- end }}
{{- $result := dict "crt" $certCrtEnc "key" $certKeyEnc "ca" $caCertEnc }}
{{- $result | toYaml }}
{{- end }}