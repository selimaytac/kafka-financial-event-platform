# 0036. Inject cluster parameters once, support all chart sources, and diff server-side

- **Status:** Accepted
- **Date:** 2026-09-26
- **Amends:** [0030](0030-generate-applications-with-applicationsets.md)

## Context

The first ApplicationSet ([0030](0030-generate-applications-with-applicationsets.md))
received profile, substrate and Git revision through JSON patches that targeted fixed list
positions in the template, and supported only charts from HTTPS Helm repositories. New
components are published as OCI charts (Envoy Gateway) or live in this repository (the
gateway configuration). Gateway API resources also stayed permanently out of sync, because
the API server fills in defaults that a client-side comparison sees as drift.

## Options

| Concern | Option | Trade-off |
|---|---|---|
| Parameters | Patches on list positions | Break silently when the template changes |
| | **Matrix generator: component files × one list element (profile, substrate, revision)** | One injection point; templates use variables |
| Chart sources | One template per source type | Duplication |
| | **`templatePatch` building sources for HTTPS, OCI or local charts** | Template logic to read |
| Drift from defaults | Write every default explicitly | Brittle; breaks with CRD upgrades |
| | **Server-side diff (dry-run apply on the API server)** | More API calls |

## Decision

- The root Application replaces one list element and the Git generator's revision; nothing
  else in the tree is patched.
- Component `config.yaml` declares `chart.repoURL` + `name` + `version` (optionally
  `oci: true`) or `chart.path` for a local chart. OCI registries are declared as Argo CD
  Helm OCI repositories in `gitops/platform/argocd/values.yaml`.
- Automated components retry with backoff and use `SkipDryRunOnMissingResource`, so
  components may depend on CRDs installed by others without explicit ordering.
- Argo CD compares with server-side diff (`controller.diff.server.side`).

## Consequences

- Adding a component: a directory with `config.yaml` and values files.
- The CI render check handles all three source types.
- Server-side diff requires access to the API server for every comparison; it reflects
  what the cluster would actually store, including webhook mutations.
