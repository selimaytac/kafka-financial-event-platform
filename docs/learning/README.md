# Learning track

This project is built to learn how an enterprise event platform is designed and operated,
and to show *why* each decision is made so the reasoning can be followed and reused
([ADR 0023](../adr/0023-separate-learning-notes-from-operational-docs.md)).

| Folder | Contents |
|---|---|
| `concepts/` | One note per concept: what it is, why it exists, what can go wrong, options, how to decide |
| [`retros/`](retros/) | One retrospective per phase: system-level decisions and lessons |

## Learning path

| Phase | Concepts | Notes |
|---|---|---|
| 0 · Foundation | Decision records, shift-left repository hygiene, supply-chain pinning, regulatory mapping, documentation types | [Retro](retros/phase-0.md) |
| 1 · Cluster | Infrastructure-as-code state (backend, locking, encryption), the bootstrap problem, layered provisioning, GitOps reconciliation | _upcoming_ |
| 2 · Platform | Policy as code, metrics/logs/traces, secrets management, log retention, TLS automation | _upcoming_ |
| 3 · Kafka | Replication and ISR, KRaft quorum, TLS/SCRAM and ACLs, schema evolution | _upcoming_ |
| 4 · Apps | Exactly-once processing, deterministic state machines, order books, idempotency, market surveillance | _upcoming_ |
| 5 · Tests | Testing a platform at every layer, chaos engineering | _upcoming_ |
| 6 · Billion run | Performance methodology, end-to-end reconciliation | _upcoming_ |
| 7 · Resilience | RPO/RTO, failure domains, backup versus replication | _upcoming_ |
| 8 · Lifecycle | Upgrade ordering, irreversible changes, maintenance windows | _upcoming_ |
