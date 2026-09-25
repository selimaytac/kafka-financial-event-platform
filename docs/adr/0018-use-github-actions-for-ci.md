# 0018. Use GitHub Actions for CI

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The repository is public on GitHub. CI must lint, test, validate manifests and policies,
and scan for secrets on every pull request.

## Options

| Option | Pros | Cons |
|---|---|---|
| GitHub Actions | Native to the host, free for public repos, large action ecosystem | Vendor-specific YAML |
| Tekton / Argo Workflows in-cluster | Kubernetes-native | Needs a running cluster for CI |
| GitLab CI | Strong CI | Repo is on GitHub |

## Decision

Use **GitHub Actions**. CI reuses the same entry points as local development
(`task lint`, `task test`, ...) so local and CI checks cannot diverge.

## Consequences

- Third-party actions are pinned by commit SHA (supply-chain control).
- kind can run inside Actions for cluster-level tests (Chainsaw).
