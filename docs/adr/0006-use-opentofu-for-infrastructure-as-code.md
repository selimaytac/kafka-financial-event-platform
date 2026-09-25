# 0006. Use OpenTofu for infrastructure as code

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Layers 0 and 1 ([0003](0003-layered-portable-provisioning.md)) need a declarative IaC tool
with providers for kind, Proxmox, Talos, Helm and Kubernetes. The project prefers
OSI-licensed tools. Terraform moved from MPL-2.0 to the Business Source License (BUSL-1.1)
in 2023, which is not an open-source license.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| OpenTofu | MPL-2.0 (Linux Foundation) | Drop-in Terraform-compatible, same providers, state encryption built in | Smaller ecosystem mindshare |
| Terraform | BUSL-1.1 | Largest mindshare | Not open source |
| Pulumi | Apache-2.0 | Real programming languages | Different model, heavier for simple modules |
| Crossplane | Apache-2.0 | Kubernetes-native | Needs a cluster to create the cluster |

## Decision

Use **OpenTofu** for Layer 0 (substrate) and Layer 1 (GitOps bootstrap). OpenTofu stops
there: everything inside the cluster is owned by GitOps ([0007](0007-use-argo-cd-for-gitops.md)).

## Consequences

- Provider versions pinned via `.terraform.lock.hcl` (committed).
- State encryption should be enabled once remote state is introduced.
- State files and plans are gitignored; no secrets in variables committed to the repo.
