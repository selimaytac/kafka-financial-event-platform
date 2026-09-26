# 0027. Organise the repository by layer and select profiles explicitly

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The layered model ([0003](0003-layered-portable-provisioning.md)) must show in the
repository: what is substrate-specific, what changes often, and what each `apply` can
affect. OpenTofu distinguishes reusable **modules** (no state) from **root modules**
(stacks), each with exactly one state; the stack boundary is the blast radius. The same
stack must run as several profiles (`dev`, `perf`, `dr`) with separate state.

## Options

Profile separation:

| Option | Pros | Cons |
|---|---|---|
| Workspaces | Built in, no duplication | Active workspace is implicit; wrong-workspace `apply`/`destroy` is a classic accident; not recommended for environments needing separate access or credentials |
| Directory per profile | Fully explicit | Duplicated code drifts apart |
| **Var file + backend key per profile, selected by a wrapper** | One code path; profile named on every command; var file and state key cannot mismatch | Requires the wrapper |

GitOps location:

| Option | Pros | Cons |
|---|---|---|
| Separate config repository (Argo CD best practice) | Independent access control and history; no CI loops from image-tag commits | Two repositories and pipelines to coordinate |
| **Monorepo with an isolated `gitops/` tree** | One place to learn from; simple | Deviates from Argo CD guidance; split later if needed |

## Decision

```
infra/modules/<module>/          reusable, no backend or provider configuration
infra/stacks/<stack>/            one state each (foundation/store, foundation/bucket,
                                 substrate-kind, substrate-proxmox, bootstrap, github)
infra/stacks/<stack>/profiles/<profile>.tfvars
gitops/root/                     app-of-apps entry point
gitops/{platform,apps}/<component>/{base,overlays/<profile>}
services/<service>/              Go source (Phase 4)
```

- State key: `<stack>/<profile>/terraform.tfstate`. Profiles are chosen only through
  `task` targets that set both the var file and the state key.
- GitOps stays in this repository under `gitops/`, a deliberate deviation from the Argo CD
  recommendation for a single-maintainer learning project.

## Consequences

- Stacks change at different speeds (foundation rarely, apps often) without sharing a
  blast radius.
- Only `infra/modules/*-cluster` and `infra/stacks/substrate-*` know the substrate.
- If the project gains separate deployers or automated image updates, `gitops/` moves to
  its own repository.
