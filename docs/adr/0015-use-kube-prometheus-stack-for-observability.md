# 0015. Use kube-prometheus-stack for metrics and dashboards

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Throughput, consumer lag, end-to-end latency and resource use must be measured to prove
the billion-event goal and to operate the platform. Strimzi exposes Prometheus metrics.
The log pipeline is a separate, open decision (Phase 2).

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| kube-prometheus-stack (Prometheus Operator, Alertmanager, Grafana) | Apache-2.0 (Grafana AGPL-3.0) | Standard, ServiceMonitor CRDs, Strimzi examples | Grafana is copyleft (fine for self-hosted use) |
| VictoriaMetrics stack | Apache-2.0 | Lighter, efficient | Fewer ready examples for Strimzi |
| Managed SaaS | — | No ops | Not local, not open source |

## Decision

Use **kube-prometheus-stack** with Strimzi's metrics and dashboards; SLOs and alert
routing are defined in later phases.

## Consequences

- Grafana is AGPL-3.0: used unmodified as a service, which is acceptable; noted for awareness.
- Prometheus retention is sized per profile to respect the disk budget.
