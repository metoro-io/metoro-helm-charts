# Metoro Helm Charts

This repository contains the Helm Charts for Metoro.

## Metoro Exporter

Metoro exporter is a collection of components that collects traces, logs, metrics and profiling data from a Kubernetes
cluster and exports them back to metoro.

### Upgrading

Update the chart repository and upgrade an existing exporter release with:

```bash
helm repo update metoro-exporter

helm upgrade metoro-exporter metoro-exporter/metoro-exporter \
  --namespace metoro \
  --reuse-values \
  --wait \
  --timeout 10m
```

Use `--version <chart-version>` to upgrade to a specific chart version.

The `--reuse-values` flag preserves the values stored with the existing Helm
release, including the exporter bearer token, ExternalSecret configuration,
resource settings, and scheduling configuration. If the release or namespace
has a different name, replace `metoro-exporter` or `metoro` in the command.

Values changed directly on live Kubernetes resources are not stored by Helm and
may be overwritten during an upgrade. Configure the exporter token through Helm
values or an ExternalSecret rather than editing `Secret/exporter-secret`
directly.

### Interesting values

All of the values can be seen in the `values.yaml` file. However it is quite large so here are some of the more
interesting values.

#### Scheduling

| Key                                 | Type | Default | Description                                                                                                           |
|-------------------------------------|------|---------|-----------------------------------------------------------------------------------------------------------------------|
| `exporter.scheduling.nodeSelector`  | map  | `{}`    | Node selector for the metoro exporter pod                                                                             |
| `exporter.scheduling.tolerations`   | list | `[]`    | Tolerations for the metoro exporter pod                                                                               |
| `exporter.scheduling.affinity`      | map  | `{}`    | Affinity for the metoro exporter pod                                                                                  |
| `nodeAgent.scheduling.nodeSelector` | map  | `{}`    | Node selector for the metoro node agent pods (be careful as this could cause some applications not to be instrumented) |
| `nodeAgent.scheduling.tolerations`  | list | `[]`    | Tolerations for the metoro node agent pods (be careful as this could cause some applications not to be instrumented)  |
| `nodeAgent.scheduling.affinity`     | map  | `{}`    | Affinity for the metoro node agent pods (be careful as this could cause some applications not to be instrumented)     |
| `redis.master.nodeSelector`         | map  | `{}`    | Node selector for the exporter redis instance                                                                         |
| `redis.master.tolerations`          | list | `[]`    | Tolerations for the exporter redis instance                                                                           |
| `redis.master.affinity`             | map  | `{}`    | Affinity for the exporter redis instance                                                                              |
| `exporter.envVars.optional.k8sResources` | string | `""` | Optional comma-separated Kubernetes resource selectors passed to `METORO_K8S_RESOURCES`; leave empty to watch all supported resources |
| `exporter.envVars.optional.honorMetoroPodAnnotations` | bool | `true` | Honor `metoro.io/exclude-logs` and `metoro.io/exclude-traces` Pod annotations |
| `exporter.envVars.optional.honorFluentBitAnnotations` | bool | `false` | Honor `fluentbit.io/exclude: "true"` Pod annotations to exclude whole-Pod logs |

#### ServiceMonitor and PodMonitor scraping

The exporter chart deploys a pinned OpenTelemetry Collector and Target
Allocator by default. The Target Allocator discovers Prometheus Operator
`ServiceMonitor` and `PodMonitor` resources, the collector scrapes those
targets, and metrics are forwarded to the in-cluster `metoro-exporter` service
at `/api/v1/custom/otel/metrics`.

Disable scraping with:

```yaml
serviceMonitorScraping:
  enabled: false
```

This path does not install the OpenTelemetry Operator, OpenTelemetry CRDs, or
admission webhooks. A cluster using `ServiceMonitor` or `PodMonitor` scraping
must already have the `monitoring.coreos.com/v1` CRDs installed; this chart does
not install the Prometheus Operator or its CRDs.

By default, the Target Allocator matches all `ServiceMonitor` and `PodMonitor`
objects:

```yaml
serviceMonitorScraping:
  collector:
    replicas: 2
  targetAllocator:
    replicas: 2
    prometheusCR:
      serviceMonitorSelector: {}
      podMonitorSelector: {}
      namespaceSelector: {}
```

The collector and Target Allocator default to two replicas, each with a
`PodDisruptionBudget` allowing one unavailable pod. Their default scheduling
also adds preferred pod anti-affinity on `kubernetes.io/hostname` so replicas
spread across nodes when capacity allows. Set the relevant
`serviceMonitorScraping.*.scheduling.affinity` value to fully override that
default affinity.

The single `namespaceSelector` value is applied to both service monitor and pod
monitor namespace selectors in the Target Allocator config.

Useful Target Allocator checks:

```bash
kubectl -n metoro get pods,statefulset,deploy,svc,cm -l app.kubernetes.io/component=service-monitor-scraper
kubectl -n metoro get svc -l app.kubernetes.io/component=opentelemetry-targetallocator
kubectl -n metoro port-forward svc/<collector-name>-targetallocator 8080:80
curl localhost:8080/jobs | jq
```
