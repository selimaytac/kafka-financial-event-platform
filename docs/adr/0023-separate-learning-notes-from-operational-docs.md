# 0023. Present the repository as a learning project and separate learning notes from operational docs

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

This repository is a hands-on learning project: an enterprise-style platform built from
scratch to understand *why* each decision is made. Without saying so explicitly, it can be
mistaken for a ready-to-deploy exchange product. The reasoning behind decisions is also
the most valuable part to share, but mixing teaching material into runbooks or reference
documents makes those documents worse at their own job.

The Diátaxis framework distinguishes four kinds of documentation, each serving one need:
tutorials (learning by doing), how-to guides (solving a task), reference (describing what
exists) and explanation (understanding why).

## Options

| Option | Pros | Cons |
|---|---|---|
| Keep lessons out of the repository | Operational docs stay lean | The reasoning, the main learning value, is lost |
| Put explanations inside runbooks and ADRs | Everything in one place | Runbooks become hard to use under pressure; ADRs grow unfocused |
| Separate learning notes (explanation) with links to ADRs, plus phase retrospectives | Each document keeps one purpose; reasoning is preserved and discoverable | More documents to maintain |

## Decision

- The README states clearly that this is a learning project and a local reference setup,
  not a production system.
- `docs/learning/` holds explanation-type material in a neutral, educational voice:
  - `concepts/`: one note per concept (what it is, why it exists, failure modes, options,
    how an architect decides), linked to the ADR that applies it.
  - `retros/`: one retrospective per phase, limited to system-level decisions and lessons
    that hold in any environment. Incidents specific to one workstation or account are
    out of scope.
- ADRs remain short decision records; runbooks remain task-focused.

## Consequences

- A phase is not done until its concept notes and retrospective exist.
- ADRs link to concept notes for background instead of repeating it.
