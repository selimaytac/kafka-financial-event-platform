# 0031. Manage repository settings and branch protection as code

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

[ADR 0024](0024-protect-main-and-pin-third-party-code.md) introduced the `protect-main`
ruleset and repository settings through the GitHub API, leaving a follow-up: settings that
enforce change control were themselves changeable without review, and a change in the
web UI would go unnoticed.

## Options

| Option | Pros | Cons |
|---|---|---|
| Keep API/UI configuration, document it | No extra tooling | Drift is invisible; not reproducible |
| Script the API calls | Reproducible | Imperative; no plan, no drift detection |
| **OpenTofu GitHub provider, existing objects imported** | Plan shows every change; drift detected; same workflow as all other infrastructure | Needs a token with admin rights on the repository |

## Decision

- A profile-less `github` stack manages the repository settings and the `protect-main`
  ruleset. Existing objects were brought under management with `import` blocks, which
  stay in the code so a lost state can re-adopt them.
- The provider uses the GitHub CLI's token from the OS keychain at run time; no new
  secret is created ([0026](0026-keep-a-single-secret-zero-in-the-os-keychain.md)).
- The repository has `prevent_destroy` and `archive_on_destroy`.

## Consequences

- Verified: import produced no changes to GitHub; a setting changed outside the code
  (squash merge enabled) appeared in the plan and was reverted by apply.
- Changes to protection rules now go through a pull request like any other change.
- The stack is applied from a workstation, not CI: CI has no admin token by design.
