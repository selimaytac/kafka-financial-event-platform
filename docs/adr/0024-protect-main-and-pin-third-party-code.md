# 0024. Protect `main` with a ruleset and pin all third-party code by commit SHA

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

CI was meant to be the authoritative gate behind local hooks
([0020](0020-enforce-repository-hygiene-with-pre-commit.md)), but nothing forced changes
through it: `main` accepted direct pushes, so a failing check could not block anything.
Secret scanning in CI also runs only after a push; on a public repository a leaked
credential is already exposed by then.

CI actions were pinned by SHA ([0018](0018-use-github-actions-for-ci.md)), but pre-commit
hooks still referenced movable tags, although they execute third-party code on developer
workstations and in CI.

## Options

| Concern | Option | Trade-off |
|---|---|---|
| Gate | No protection | Relies on discipline; CI is advisory only |
| | Ruleset with admin bypass | Flexible, but the rule owner can silently skip the rule |
| | **Ruleset without bypass; merge on the platform** | Every change passes CI; merge happens on GitHub instead of locally |
| Push-time secrets | **GitHub secret scanning push protection** | Blocks known credential formats at push time; free for public repositories |
| Hooks | Tags | Movable; a compromised tag runs new code |
| | **Commit SHAs (`pre-commit autoupdate --freeze`)** | Immutable; upgrades become explicit diffs |

## Decision

- Ruleset `protect-main` on the default branch, with no bypass actors: changes only via
  pull request; required checks `lint (pre-commit)` and
  `secrets (gitleaks, full history)`, branch up to date; no force push; no deletion;
  merge commits only.
- The merge commit title is taken from the pull request title, so PR titles follow
  Conventional Commits. Squash and rebase merges are disabled.
- Secret scanning with push protection is enabled.
- All third-party code is content-addressed: actions and pre-commit hooks are pinned by
  commit SHA, with the version as a comment.

## Consequences

- The earlier flow of merging locally and pushing to `main` is no longer possible; merges
  use `gh pr merge --merge`.
- `pre-commit autoupdate` only considers tags reachable from each hook repository's
  default branch; releases tagged on maintenance branches must be pinned by hand.
- Follow-up: repository settings and the ruleset were applied through the GitHub API.
  They should become code (e.g. the OpenTofu GitHub provider) so they are reproducible
  like every other environment.
