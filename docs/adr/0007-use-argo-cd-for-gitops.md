# 0007. Use Argo CD (app-of-apps) for GitOps

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Layer 2 must be declarative, self-healing and auditable: the desired state lives in Git
and every change is a reviewed commit. No manual `kubectl apply` drift may remain.
Change traceability is also a governance control (who changed what, when, approved by whom).

## Options

| Option | Pros | Cons |
|---|---|---|
| Argo CD | CNCF graduated, UI for visual drift/health, app-of-apps and ApplicationSets, sync waves | Heavier than Flux |
| Flux | CNCF graduated, lightweight, composable controllers | No built-in UI; less visual for learning and demos |
| Helm/kubectl from CI | Simple | Push-based, no drift detection or self-heal |

## Decision

Use **Argo CD** with the **app-of-apps** pattern. Environment and profile differences are
Kustomize overlays (and Helm values where charts are used). Sync waves order
dependencies (CRDs/operators before workloads).

## Consequences

- Git history is the change log for the cluster (evidence for change management).
- Self-heal reverts manual changes; emergency changes must go through Git too.
- Argo CD itself is installed by OpenTofu (Layer 1) and then manages its own config.
