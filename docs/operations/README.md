# Operations: maintenance and upgrades

See also: [host footprint](host-footprint.md) (everything the lab places on the host).

Every component is expected to have a documented lifecycle before its phase is closed.

## Component lifecycle inventory

| Component | Version pin location | Upgrade path | Upgrade guide | Maintenance tasks |
|---|---|---|---|---|
| SeaweedFS (state store) | `infra/modules/seaweedfs-local/variables.tf` (`image_tag`) | Replace container; data stays on the host | _Phase 8_ | Back up data directory; verify versioning |
| cloud-provider-kind | `infra/stacks/substrate-kind-shared/variables.tf` (digest) | Replace container | _Phase 8_ | — |
| kind node image (Kubernetes) | `infra/stacks/substrate-kind/profiles/*.tfvars` (digest) | One minor version at a time: 1.35 → 1.36 → 1.37 | _Phase 8_ | — |
| Cilium | `gitops/platform/cilium/config.yaml` | Git change; Argo CD rolls out | _Phase 8_ | Hubble certificate CronJob health |
| Talos Linux (Proxmox substrate) | `infra/modules/proxmox-talos-cluster/variables.tf` (`talos_version`, `kubernetes_version`) | Image-based rolling upgrade | _Phase 8_ | — |
| Argo CD | `gitops/platform/argocd/config.yaml` | Git change; Argo CD upgrades itself | _Phase 8_ | — |
| Strimzi operator | _Phase 3_ | Operator first, then Kafka version, then metadata version | _Phase 8_ | Certificate renewal, rebalancing |
| Kafka | _Phase 3_ | Rolling restart by Strimzi | _Phase 8_ | Partition reassignment, retention review |
| ClickHouse | _Phase 4_ | Rolling replica upgrade | _Phase 8_ | Merges, TTL, backup verification |
| Valkey | _Phase 4_ | Replica-first failover | _Phase 8_ | Memory review |
| cert-manager | `gitops/platform/cert-manager/config.yaml` | Git change; CRDs kept on removal | _Phase 8_ | Certificate expiry and renewal |
| Envoy Gateway | `gitops/platform/envoy-gateway/config.yaml` (OCI) | Git change | _Phase 8_ | — |
| Lab PKI | `infra/stacks/pki/main.tf` | Intermediates re-issued 30 days before expiry (plan shows it) | _Phase 8_ | Yearly intermediate rotation |
| Kyverno | _Phase 2_ | Helm chart | _Phase 8_ | Policy report review |
| kube-prometheus-stack | `gitops/platform/monitoring/config.yaml` | Git change; large CRDs need server-side apply | _Phase 8_ | Retention, cardinality and limit review against measurements |

## Upgrade principles

1. Read upstream release notes and upgrade guide; record breaking changes.
2. Upgrade in `dev` first, via a Git change (never by hand).
3. Order: CRDs → operators → workloads.
4. Define the rollback path *before* upgrading; note what is not reversible
   (e.g. Kafka metadata version).
5. Verify with health checks and smoke tests; record the outcome.

## Maintenance plan

To be defined in Phase 8: scheduled tasks, cadence and owners per component.
