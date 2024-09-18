# Metoro Helm Charts

This repository contains the Helm Charts for Metoro.

## Metoro Exporter

Metoro exporter is a collection of components that collects traces, logs, metrics and profiling data from a Kubernetes
cluster and exports them back to metoro.

### Interesting values

All of the values can be seen in the `values.yaml` file. However it is quite large so here are some of the more
interesting values.

#### Scheduling

| Key                                          | Type | Default | Description                                                                                                            |
|----------------------------------------------|------|---------|------------------------------------------------------------------------------------------------------------------------|
| `exporter.scheduling.nodeSelector`           | map  | `{}`    | Node selector for the metoro exporter pod                                                                              |
| `exporter.scheduling.tolerations`            | list | `[]`    | Tolerations for the metoro exporter pod                                                                                |
| `exporter.scheduling.affinity`               | map  | `{}`    | Affinity for the metoro exporter pod                                                                                   |
| `nodeAgent.scheduling.nodeSelector`          | map  | `{}`    | Node selector for the metoro node agent pods (be careful as this could cause some applications not to be instrumented) |
| `nodeAgent.scheduling.tolerations`           | list | `[]`    | Tolerations for the metoro node agent pods (be careful as this could cause some applications not to be instrumented)   |
| `nodeAgent.scheduling.affinity`              | map  | `{}`    | Affinity for the metoro node agent pods (be careful as this could cause some applications not to be instrumented)      |
| `clusterServer.scheduling.nodeSelector`      | map  | `{}`    | Node selector for the metoro cluster server pod                                                                        |
| `clusterServer.scheduling.tolerations`       | list | `[]`    | Tolerations for the metoro cluster server pod                                                                          |
| `clusterServer.scheduling.affinity`          | map  | `{}`    | Affinity for the metoro cluster server pod                                                                             |
| `prometheus.server.nodeSelector`             | map  | `{}`    | Node selector for the prometheus pod                                                                                   |
| `prometheus.server.tolerations`              | list | `[]`    | Tolerations for the prometheus pod                                                                                     |
| `prometheus.server.affinity`                 | map  | `{}`    | Affinity for the prometheus pod                                                                                        |
| `prometheus.kube-state-metrics.nodeSelector` | map  | `{}`    | Node selector for the kube-state-metrics pod                                                                           |
| `prometheus.kube-state-metrics.tolerations`  | list | `[]`    | Tolerations for the kube-state-metrics pod                                                                             |
| `prometheus.kube-state-metrics.affinity`     | map  | `{}`    | Affinity for the kube-state-metrics pod                                                                                |
| `clickhouse.nodeSelector`                    | map  | `{}`    | Node selector for the clickhouse pod                                                                                   |
| `clickhouse.tolerations`                     | list | `[]`    | Tolerations for the clickhouse pod                                                                                     |
| `clickhouse.affinity`                        | map  | `{}`    | Affinity for the clickhouse pod                                                                                        |


