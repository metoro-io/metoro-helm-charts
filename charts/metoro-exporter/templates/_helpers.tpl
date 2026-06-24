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
Common non-selector labels for ServiceMonitor scraping resources.
*/}}
{{- define "metoro.serviceMonitorScraping.commonLabels" -}}
helm.sh/chart: {{ include "metoro.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the ServiceMonitor scraping collector.
*/}}
{{- define "metoro.serviceMonitorScraping.collectorName" -}}
{{- printf "%s-sm-scraper" (include "metoro.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the ServiceMonitor scraping collector config map.
*/}}
{{- define "metoro.serviceMonitorScraping.collectorConfigMapName" -}}
{{- printf "%s-config" (include "metoro.serviceMonitorScraping.collectorName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the ServiceMonitor scraping collector headless service.
*/}}
{{- define "metoro.serviceMonitorScraping.collectorHeadlessServiceName" -}}
{{- printf "%s-headless" (include "metoro.serviceMonitorScraping.collectorName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the service account name used by the ServiceMonitor scraping collector.
*/}}
{{- define "metoro.serviceMonitorScraping.collectorServiceAccountName" -}}
{{- printf "%s-collector" (include "metoro.serviceMonitorScraping.collectorName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create selector labels used by the ServiceMonitor scraping collector.
*/}}
{{- define "metoro.serviceMonitorScraping.collectorSelectorLabels" -}}
app.kubernetes.io/name: {{ include "metoro.serviceMonitorScraping.collectorName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: service-monitor-scraper
{{- end }}

{{/*
Create the name used by the Target Allocator resources.
*/}}
{{- define "metoro.serviceMonitorScraping.targetAllocatorName" -}}
{{- $suffix := "-targetallocator" -}}
{{- $prefixLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" ((include "metoro.serviceMonitorScraping.collectorName" .) | trunc $prefixLength | trimSuffix "-") $suffix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the service account name used by the Target Allocator.
*/}}
{{- define "metoro.serviceMonitorScraping.serviceAccountName" -}}
{{- include "metoro.serviceMonitorScraping.targetAllocatorName" . }}
{{- end }}

{{/*
Create selector labels used by the Target Allocator.
*/}}
{{- define "metoro.serviceMonitorScraping.targetAllocatorSelectorLabels" -}}
app.kubernetes.io/name: {{ include "metoro.serviceMonitorScraping.targetAllocatorName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: opentelemetry-targetallocator
{{- end }}

{{/*
Common non-selector labels for plugin resources.
*/}}
{{- define "metoro.plugins.commonLabels" -}}
helm.sh/chart: {{ include "metoro.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the CloudWatch plugin.
*/}}
{{- define "metoro.plugins.cloudwatch.name" -}}
{{- printf "%s-plugin-cloudwatch" (include "metoro.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the CloudWatch plugin scraper (YACE) config map.
*/}}
{{- define "metoro.plugins.cloudwatch.configMapName" -}}
{{- printf "%s-config" (include "metoro.plugins.cloudwatch.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the CloudWatch plugin collector sidecar config map.
*/}}
{{- define "metoro.plugins.cloudwatch.sidecarConfigMapName" -}}
{{- printf "%s-sidecar-config" (include "metoro.plugins.cloudwatch.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create selector labels used by the CloudWatch plugin.
*/}}
{{- define "metoro.plugins.cloudwatch.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metoro.plugins.cloudwatch.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: plugin-cloudwatch
{{- end }}

{{/*
Render the YACE configuration for the CloudWatch plugin from the curated metric
sets in files/plugins/cloudwatch and the user's plugins.cloudwatch.services values.
*/}}
{{- define "metoro.plugins.cloudwatch.yaceConfig" -}}
{{- $cw := .Values.plugins.cloudwatch -}}
{{- if $cw.customConfig -}}
{{- $cw.customConfig -}}
{{- else -}}
{{- $jobs := list -}}
{{- range $svc := $cw.services -}}
{{- $path := printf "files/plugins/cloudwatch/%s.yaml" $svc.name -}}
{{- $curatedRaw := $.Files.Get $path -}}
{{- if not $curatedRaw -}}
{{- fail (printf "plugins.cloudwatch: unsupported service %q. Supported services: rds, sqs, lambda, alb, elasticache, dynamodb. Use plugins.cloudwatch.customConfig for anything else." $svc.name) -}}
{{- end -}}
{{- $curated := fromYaml $curatedRaw -}}
{{- $period := int ($svc.period | default $cw.scrape.period) -}}
{{- $job := dict
      "type" $curated.type
      "regions" ($svc.regions | default $cw.aws.regions)
      "period" $period
      "length" $period
      "delay" (int $cw.scrape.delay)
      "nilToZero" $cw.scrape.nilToZero
      "metrics" ($svc.metrics | default $curated.metrics)
-}}
{{- with $svc.searchTags -}}
{{- $_ := set $job "searchTags" . -}}
{{- end -}}
{{- $jobs = append $jobs $job -}}
{{- end -}}
{{- $config := dict
      "apiVersion" "v1alpha1"
      "sts-region" $cw.aws.stsRegion
      "discovery" (dict "jobs" $jobs)
-}}
{{- toYaml $config -}}
{{- end -}}
{{- end }}

{{/*
Render a Kubernetes LabelSelector for the Target Allocator config. The pinned
Target Allocator version unmarshals LabelSelector fields using lower-case YAML
field names.
*/}}
{{- define "metoro.serviceMonitorScraping.targetAllocatorLabelSelector" -}}
{{- $selector := . | default dict -}}
{{- $matchLabels := get $selector "matchLabels" | default (get $selector "matchlabels") -}}
{{- $matchExpressions := get $selector "matchExpressions" | default (get $selector "matchexpressions") -}}
{{- if or $matchLabels $matchExpressions -}}
{{- with $matchLabels }}
matchlabels:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $matchExpressions }}
matchexpressions:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- else -}}
{}
{{- end -}}
{{- end }}
