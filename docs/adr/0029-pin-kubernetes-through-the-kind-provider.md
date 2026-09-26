# 0029. Pin Kubernetes through the kind provider, by image digest

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The local substrate is created with the OpenTofu kind provider (`tehcyx/kind` v0.11.0),
which embeds kind v0.31.0 as a library. A kind release supports the node images built for
it; kind v0.31.0 defaults to Kubernetes 1.35.0. The latest kind (v0.33.0) ships
Kubernetes 1.37.0, so the provider trails upstream by two minor versions. Kubernetes
supports the three most recent minor releases, so 1.35 is supported but late in its window.

kind rebuilds node images and pushes them under the **same tag**: `kindest/node:v1.35.0`
currently resolves to a different digest than the one kind v0.31.0 was released with.
Tags are therefore not a stable reference.

## Options

| Option | Pros | Cons |
|---|---|---|
| **kind provider, Kubernetes 1.35.0 pinned by the digest from kind v0.31.0** | Declarative: state, plan and drift detection | Two minor versions behind |
| kind CLI via `local-exec` (Kubernetes 1.37) | Latest version | Imperative: OpenTofu does not track the cluster |
| Fork the provider | Current and declarative | Maintenance burden on this project |

## Decision

Use the kind provider with `kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f` (the digest published
with kind v0.31.0). The digest lives in the substrate stack's profile variables.
The kubeconfig is written to a separate file per cluster, never merged into the user's
default kubeconfig.

## Consequences

- Upgrading Kubernetes is a planned scenario (Phase 8): 1.35 → 1.36 → 1.37, one minor
  version at a time, as Kubernetes requires.
- Moving to a newer kind requires a provider release that embeds it; the provider version
  and node image digest change together.
