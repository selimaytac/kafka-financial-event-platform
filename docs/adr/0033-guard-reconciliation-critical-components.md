# 0033. Guard reconciliation-critical components: manual sync and pre-merge rendering

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Argo CD manages itself and the CNI ([0030](0030-generate-applications-with-applicationsets.md)).
A bad change to either can stop reconciliation altogether: a crashing application
controller (a StatefulSet, replaced pod-first) or a broken CNI leaves nothing to apply the
fix. Recovery then needs break-glass access, and the order matters: Git must be corrected
first, or the recovered controller re-applies the broken state.

## Options

| Option | Pros | Cons |
|---|---|---|
| Automated sync everywhere | Uniform; drift corrected immediately | A bad commit to Argo CD or the CNI rolls out unattended |
| **Manual sync for reconciliation-critical components; automated for the rest** | A person triggers changes that could remove the ability to recover; drift is still reported (OutOfSync) | No automatic drift correction for those components |
| Sync windows (time-boxed automated sync) | Changes only in maintenance windows | Adds scheduling; does not stop a bad change inside the window |

Prevention before merge:

| Option | Catches |
|---|---|
| Lint YAML only | Syntax |
| **Render every component for every profile and substrate; validate with the chart's values schema and Kubernetes/CRD schemas (kubeconform)** | Invalid values, wrong types, unknown fields, removed APIs for the target Kubernetes version |
| Also diff against the live cluster in PRs | Unintended changes; needs cluster access from CI (later) |

## Decision

- Each component declares `sync: automated` or `sync: manual` in its `config.yaml`; the
  ApplicationSet enables automated sync through `templatePatch`. Cilium and Argo CD are
  `manual`. `task argo:sync APP=<name>` triggers a sync.
- CI runs `task gitops:check`: every component × profile × substrate is rendered with
  `helm template` for Kubernetes 1.35 and validated with kubeconform (CRD schemas from a
  catalog pinned by commit). CustomResourceDefinition objects are skipped explicitly
  because the schema repository publishes no schema for them.
- Break-glass recovery follows the [Argo CD recovery runbook](../runbooks/recover-argocd.md):
  revert in Git first, then reinstall from the corrected state.

## Consequences

- Upgrading Cilium or Argo CD is a two-step change: merge, then a deliberate sync.
- Verified: an invalid value was rejected by the chart's schema during rendering.
- OutOfSync on manual components needs an alert (Phase 2 monitoring), otherwise drift
  there is visible only in the UI.
