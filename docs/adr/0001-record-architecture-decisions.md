# 0001. Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

This platform models systems from a regulated domain (a securities exchange). In that
domain, *why* a system is built a certain way matters as much as *how*: auditors, new
team members and future maintainers need the reasoning, the alternatives that were
rejected and the known trade-offs. Decisions also change over time (upgrades, new
substrates), so the history must be preserved, not overwritten.

## Options

| Option | Pros | Cons |
|---|---|---|
| Architecture Decision Records in the repo | Versioned with the code, reviewable in PRs, cheap | Needs discipline to keep writing them |
| Wiki / external document | Rich editing | Drifts from the code, not reviewed with changes |
| Only code comments and README | Zero overhead | Loses rejected alternatives and history |

## Decision

Record every significant decision as a short ADR in `docs/adr/NNNN-title.md` using
[`template.md`](template.md): **Context · Options · Decision · Consequences**.
ADRs are immutable once merged to `main`; a changed decision gets a new ADR that supersedes
the old one. The README decision table links to the ADRs.

## Consequences

- Each phase is not done until its decisions are recorded as ADRs.
- The ADR log doubles as change-management evidence (see `docs/compliance/`).
- Small, reversible choices (e.g. a library minor version) do not need an ADR.
