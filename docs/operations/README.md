# Operations: maintenance and upgrades

Every component is expected to have a documented lifecycle before its phase is closed.

## Component lifecycle inventory

| Component | Version pin location | Upgrade path | Upgrade guide | Maintenance tasks |
|---|---|---|---|---|
| kind node image | _Phase 1_ | Recreate cluster with new image | _Phase 8_ | — |
| Talos Linux | _Phase 1_ | Image-based rolling upgrade | _Phase 8_ | — |
| Argo CD | _Phase 1_ | Helm chart, self-managed | _Phase 8_ | — |
| Strimzi operator | _Phase 3_ | Operator first, then Kafka version, then metadata version | _Phase 8_ | Certificate renewal, rebalancing |
| Kafka | _Phase 3_ | Rolling restart by Strimzi | _Phase 8_ | Partition reassignment, retention review |
| ClickHouse | _Phase 4_ | Rolling replica upgrade | _Phase 8_ | Merges, TTL, backup verification |
| Valkey | _Phase 4_ | Replica-first failover | _Phase 8_ | Memory review |
| Kyverno | _Phase 2_ | Helm chart | _Phase 8_ | Policy report review |
| kube-prometheus-stack | _Phase 2_ | Helm chart (CRDs first) | _Phase 8_ | Retention and cardinality review |

## Upgrade principles

1. Read upstream release notes and upgrade guide; record breaking changes.
2. Upgrade in `dev` first, via a Git change (never by hand).
3. Order: CRDs → operators → workloads.
4. Define the rollback path *before* upgrading; note what is not reversible
   (e.g. Kafka metadata version).
5. Verify with health checks and smoke tests; record the outcome.

## Maintenance plan

To be defined in Phase 8: scheduled tasks, cadence and owners per component.
