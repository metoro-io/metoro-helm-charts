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

## On-Prem Monitored Cluster Fixtures

Use `scripts/onprem/install-monitored-apps` to install small applications into
the on-prem monitored cluster for exporter scraping tests. By default it uses
the monitored kubeconfig from the sibling `metoro-observability` checkout,
installs the Prometheus Operator CRDs, and installs `podinfo` with a
`ServiceMonitor`.

```bash
scripts/onprem/install-monitored-apps
```

Override the kubeconfig when needed:

```bash
ONPREM_MONITORED_KUBECONFIG=/path/to/monitored-kubeconfig \
  scripts/onprem/install-monitored-apps
```

Verify the installed fixture:

```bash
KUBECONFIG=/path/to/monitored-kubeconfig kubectl get servicemonitor -A
KUBECONFIG=/path/to/monitored-kubeconfig kubectl -n servicemonitor-fixtures get pods,svc,servicemonitor
```
