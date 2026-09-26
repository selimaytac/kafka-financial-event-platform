# 0030. Generate Argo CD Applications with ApplicationSets; OpenTofu owns only the root

- **Status:** Accepted
- **Date:** 2026-09-26
- **Supersedes:** [0007](0007-use-argo-cd-for-gitops.md) (the app-of-apps pattern; Argo CD itself remains)

## Context

[ADR 0007](0007-use-argo-cd-for-gitops.md) chose Argo CD with the app-of-apps pattern: a
root Application pointing at hand-written child Applications. Every new component needs
another near-identical manifest, and the profile has to be repeated in each one.
Bootstrap-and-adopt ([0028](0028-use-cilium-as-cni-with-bootstrap-and-adopt.md)) also
raised the question of ownership: two controllers managing one resource revert each
other's changes indefinitely.

## Options

| Option | Pros | Cons |
|---|---|---|
| App-of-apps with hand-written Applications | Explicit, easy to read | Repetition per component and profile |
| **ApplicationSet with a Git files generator** | A component is added by adding `gitops/platform/<name>/config.yaml`; profile and revision are set once | One more abstraction to understand |

Ownership after bootstrap:

| Option | Pros | Cons |
|---|---|---|
| **Install once with OpenTofu, ignore changes, Argo CD owns** | One change path (Git); a new cluster bootstraps the same way | The releases stay in OpenTofu state without being managed; must be documented |
| OpenTofu keeps owning Cilium and Argo CD | Ownership obvious; Argo CD cannot break itself | Two change paths |

## Decision

- An ApplicationSet (`gitops/root/applicationset-platform.yaml`) generates one Application
  per `gitops/platform/*/config.yaml`, using the chart and version from that file and
  `values.yaml` plus `values-<profile>.yaml` from the same directory.
- The bootstrap stack creates exactly one object that it keeps owning: the **root
  Application**, which injects the profile and Git revision through inline Kustomize patches.
- Cilium and Argo CD are installed by the bootstrap stack with `ignore_changes = all`
  and then owned by Argo CD. Both sides read the same `config.yaml` and values files.
- `preserveResourcesOnDeletion` protects running components if a directory is removed.

## Consequences

- Each resource has a single writer; verified: a manual deletion is restored by Argo CD,
  and a new OpenTofu plan of the bootstrap stack shows no changes.
- If Argo CD breaks itself through a bad commit, recovery is to revert the commit and, if
  needed, re-apply the bootstrap stack (runbook).
- Ordering between generated Applications is not guaranteed by sync waves; components that
  need ordering (e.g. CRDs before users) must tolerate retries or be handled explicitly.
