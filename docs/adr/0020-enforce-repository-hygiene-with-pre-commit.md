# 0020. Enforce repository hygiene with pre-commit, gitleaks and Conventional Commits

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The repository is public. A leaked credential is an incident; an unreadable history
weakens change traceability. Checks must run before code leaves the developer's machine, and the same
checks must run in CI.

## Options

| Concern | Chosen | Alternative | Why chosen |
|---|---|---|---|
| Hook framework | pre-commit | lefthook, husky | Language-agnostic, pinned hook versions, reused in CI |
| Secret scanning | gitleaks | trufflehog | Fast, pre-commit native, MIT |
| Commit message lint | conventional-pre-commit | commitlint | Python, fits pre-commit; no Node dependency |
| Task runner | Task (Taskfile) | Make | YAML, cross-platform, readable |

## Decision

Use **pre-commit** with gitleaks, basic file-hygiene hooks, **Conventional Commits**
validation and a 72-character subject limit. Common workflows are exposed via **Task**.
Main stays deployable; each phase is developed on its own branch.

## Consequences

- `task setup` must be run once per clone to install the hooks.
- Hook versions are pinned; `task hooks:update` bumps them in a reviewed commit.
- Conventional Commit history enables automated changelogs later.
- Merge commits must also use Conventional Commit messages (e.g.
  `chore: merge phase 0 foundation`); the default "Merge branch ..." message is rejected.
