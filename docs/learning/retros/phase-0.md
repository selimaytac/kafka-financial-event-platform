# Phase 0 retrospective: foundation

**Goal:** a repository that enforces its own hygiene, records every decision, and has a
design baseline before any infrastructure exists.

## Lessons

### 1. Decide the domain before the architecture

An "exchange and payments" scope was narrowed to a securities exchange. The two domains
stress different things: an exchange is dominated by event volume, ordering and latency;
payments are dominated by ledger consistency and reconciliation. Serving both would dilute
every downstream decision (stores, schemas, controls). The market model then shaped
operations: trading phases create natural maintenance windows, which later drive the
upgrade strategy ([ADR 0021](../../adr/0021-model-a-mifid-style-regulated-equity-market.md)).

**Takeaway:** scope is an architectural decision; it determines which quality attributes
matter most.

### 2. Decision records are immutable only once they are merged

ADRs were revised several times while the phase was still on its branch. Treating an ADR
as final the moment it is written makes early design painful; treating it as editable
after merge destroys its value as history. The workable rule: edit freely until the
decision is merged, supersede with a new ADR afterwards
([ADR 0001](../../adr/0001-record-architecture-decisions.md)).

### 3. A local check is not a complete check

The gitleaks pre-commit hook scans **staged changes only**. It prevents new secrets from
entering, but it cannot see what is already in history, for example after a rebase or on
a clone that skipped the hooks. CI therefore runs a separate **full-history** scan. The
same pattern applies to any shift-left control: the local hook gives fast feedback, and the
CI job is the authoritative gate ([ADR 0020](../../adr/0020-enforce-repository-hygiene-with-pre-commit.md)).

### 4. `commit-msg` hooks also judge merge commits

With strict Conventional Commits validation, git's default `Merge branch ...` message is
rejected, because `commit-msg` hooks run on merges too. Hosting-platform merge buttons have
the same problem: their default titles bypass the local hook entirely. Merges therefore use
explicit conventional messages, e.g. `chore: merge phase 0 foundation`.

### 5. Git inside containers checks repository ownership

Since git 2.35.2 (CVE-2022-24765), git refuses to operate on a repository owned by a
different user ("dubious ownership"). A CI job that mounts the checkout into a container
running as another user hits this; a macOS workstation with Docker Desktop hides it because
file ownership is translated. The fix is to declare the mounted path as a
`safe.directory` for that process only, not to disable the check globally.

**Takeaway:** a green local run of a container step does not prove the CI run; know
which platform behaviours differ.

### 6. Pin CI dependencies by commit SHA

A version tag like `v4` can be moved by whoever controls the action's repository. In
March 2025 the `tj-actions/changed-files` action was compromised by exactly this: tags were
repointed to malicious code that leaked CI secrets (CVE-2025-30066). Pinning to a full
commit SHA, with the version as a comment, makes the dependency immutable; upgrades become
explicit, reviewable changes ([ADR 0018](../../adr/0018-use-github-actions-for-ci.md)).

### 7. Regulatory references expire

A control matrix is not written once. Rules are superseded and dated changes are already
scheduled; for example, EU securities settlement moves from T+2 to T+1 on
11 October 2027. Every reference therefore cites its source, and the matrix is reviewed
each phase. The settlement cycle is modelled as configuration so that the switch becomes a
planned change, not a rewrite ([ADR 0019](../../adr/0019-treat-regulations-as-reference-frameworks.md)).

### 8. Validate diagrams like code

Mermaid diagrams are code; a syntax error renders as an error box, and a valid diagram
can still mislead (a component drawn outside the cluster it runs in). Rendering them with
`mermaid-cli` before publishing caught both. Diagram rendering is a candidate for CI.

### 9. Constraints are design inputs

A small resource budget did not shrink the design; it split *designed* from *running*.
Heavy scenarios (billion-event run, DR site) exist fully as code in on-demand profiles,
while only a small profile runs routinely
([ADR 0003](../../adr/0003-layered-portable-provisioning.md)).

## Carried forward

| Item | Where |
|---|---|
| Render Mermaid diagrams in CI | CI (cross-cutting) |
| Out-of-cluster object storage for IaC state and backups | Phase 1 decision |
| Review the control matrix every phase | Governance (cross-cutting) |
