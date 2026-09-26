# Learning track

This project is built to learn how an enterprise event platform is designed and operated,
and to show *why* each decision is made so the reasoning can be followed and reused
([ADR 0023](../adr/0023-separate-learning-notes-from-operational-docs.md)).

| Folder | Contents |
|---|---|
| [`concepts/`](concepts/) | One note per concept: what it is, why it exists, what can go wrong, options, how to decide |
| [`retros/`](retros/) | One retrospective per phase: system-level decisions and lessons |

## Learning path

| Phase | Concepts | Notes |
|---|---|---|
| 0 · Foundation | Decision records, shift-left repository hygiene, supply-chain pinning, regulatory mapping, documentation types | [Retro](retros/phase-0.md) |
| 1 · Cluster | Infrastructure-as-code state (backend, locking, encryption), the bootstrap problem, secret zero, layered provisioning, GitOps reconciliation | [OpenTofu state](concepts/opentofu-state.md) · [Secret zero](concepts/secret-zero.md) · [GitOps reconciliation and ownership](concepts/gitops-reconciliation-and-ownership.md) · [Cattle, not pets](concepts/cattle-not-pets.md) · [Retro](retros/phase-1.md) |
| 2 · Platform | Policy as code, metrics/logs/traces, secrets management, log retention, TLS automation | [PKI and trust anchors](concepts/pki-and-trust-anchors.md) |
| 3 · Kafka | Replication and ISR, KRaft quorum, TLS/SCRAM and ACLs, schema evolution | _upcoming_ |
| 4 · Apps | Exactly-once processing, deterministic state machines, order books, idempotency, market surveillance | _upcoming_ |
| 5 · Tests | Testing a platform at every layer, chaos engineering | _upcoming_ |
| 6 · Billion run | Performance methodology, end-to-end reconciliation | _upcoming_ |
| 7 · Resilience | RPO/RTO, failure domains, backup versus replication | _upcoming_ |
| 8 · Lifecycle | Upgrade ordering, irreversible changes, maintenance windows | _upcoming_ |
