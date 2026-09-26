# Observability and resource bounds

Applied in [ADR 0037](../../adr/0037-measure-and-bound-the-platform-with-kube-prometheus-stack.md)
and [ADR 0034](../../adr/0034-run-the-lab-as-a-guest-on-its-host.md).

## Metrics: what they cost

Prometheus pulls (scrapes) each target's `/metrics` endpoint at an interval. Every distinct
combination of label values is a separate time series, and memory grows with the number of
active series (cardinality). A label with unbounded values (user, order or account IDs) can
exhaust a Prometheus server in minutes.

## What to measure

- **USE** for resources: utilisation, saturation, errors.
- **RED** for services: rate, errors, duration.
- Platform health: reconciliation (is Git applied?), certificate renewal, CNI health.

## Alerts

Alert on symptoms (users or operations are affected), not on every cause. Each alert must be
actionable and point to a runbook. Alerts that fire without anyone needing to act (false
positives, e.g. clock sync in container-based nodes) are removed, not ignored; otherwise
real alerts get ignored too. A permanent "watchdog" alert proves the alerting path works.

## Resource bounds: requests, limits and the host

- **Requests** reserve capacity for scheduling; **limits** cap usage. Memory limits stop a
  process at the limit (OOM kill), CPU limits throttle it. CPU is compressible, memory is not.
- A memory limit set below real usage does not fail cleanly: the kernel reclaims pages first,
  and the process slows down under memory pressure (thrashing) long before it is killed.
  Limits come from measurements, with headroom.
- **Pod limits protect the node, not the host.** When nodes are themselves containers or VMs,
  the host needs its own bound on them; otherwise a burst inside the cluster can saturate the
  machine it runs on.

## Probes

- **Liveness:** "is the process stuck?" Failure restarts the container.
- **Readiness:** "can it serve traffic now?" Failure removes it from load balancing.
- **Startup:** "has it finished starting?" Holds liveness off until it succeeds. Without it,
  a slow first start can be killed by liveness again and again.

## How to decide

1. Measure before limiting; set memory limits above observed peaks.
2. Bound every layer: pods, nodes, and the host the nodes run on.
3. Keep label values bounded in every metric you define.
4. For each alert, name the action and the runbook; delete alerts that have neither.
