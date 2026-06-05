# Metoro Helm Charts

This repository contains the Helm Charts for Metoro.

## Metoro Exporter

Metoro exporter is a collection of components that collects traces, logs, metrics and profiling data from a Kubernetes
cluster and exports them back to metoro.

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

#### ServiceMonitor and PodMonitor scraping

The exporter chart can optionally deploy an OpenTelemetry Collector managed by
the OpenTelemetry Operator. The collector uses the Target Allocator to discover
Prometheus Operator `ServiceMonitor` and `PodMonitor` resources, scrape those
targets, and forward OTLP HTTP metrics to the in-cluster `metoro-exporter`
service at `/api/v1/custom/otel/metrics`.

If the cluster already has an OpenTelemetry Operator installed:

```yaml
serviceMonitorScraping:
  enabled: true
  operator:
    install: false
```

If the chart should install the OpenTelemetry Operator as a dependency:

```yaml
serviceMonitorScraping:
  enabled: true
  operator:
    install: true
```

The `operator.install` default is `false` because Helm dependency conditions
cannot express `serviceMonitorScraping.enabled && operator.install`. Default
installs do not install OpenTelemetry CRDs. When `operator.install=true`, a
small CRD-only dependency installs the pinned OpenTelemetry Operator CRDs before
the collector custom resource is rendered; the operator dependency's templated
CRDs stay disabled to avoid Helm ownership conflicts with pre-existing CRDs.
When the chart installs the operator, it disables the operator admission
webhooks because this scraping path does not use auto-instrumentation. A cluster
using `ServiceMonitor` or `PodMonitor` scraping must still already have the
`monitoring.coreos.com/v1` CRDs installed; this chart does not install the
Prometheus Operator or its CRDs.

By default, the Target Allocator matches all `ServiceMonitor` and `PodMonitor`
objects:

```yaml
serviceMonitorScraping:
  enabled: true
  collector:
    upgradeStrategy: automatic
  targetAllocator:
    prometheusCR:
      serviceMonitorSelector: {}
      podMonitorSelector: {}
      namespaceSelector: {}
```

The pinned OpenTelemetry Operator dependency currently supports the
`serviceMonitorSelector` and `podMonitorSelector` fields. The `namespaceSelector`
value is reserved for namespace selector support when the operator dependency is
updated; for now, namespace selection should be expressed in the
`ServiceMonitor` or `PodMonitor` resources themselves.

Useful Target Allocator checks:

```bash
kubectl -n metoro get opentelemetrycollector
kubectl -n metoro get svc -l app.kubernetes.io/component=opentelemetry-targetallocator
kubectl -n metoro port-forward svc/<collector-name>-targetallocator 8080:80
curl localhost:8080/jobs | jq
```
