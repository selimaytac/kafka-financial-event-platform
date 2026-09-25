# 0008. Run Kafka with Strimzi in KRaft mode

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Kafka is the event backbone. Apache Kafka 4.x removed ZooKeeper; KRaft is the only
metadata mode. Operating Kafka on Kubernetes needs an operator that handles rolling
upgrades, certificates, users/ACLs and topics declaratively. Finance semantics require
durable writes: no acknowledged event may be lost when one broker fails.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| Strimzi operator | Apache-2.0, CNCF incubating | Topics/users/ACLs as CRDs, rolling upgrades, TLS, node pools, Cruise Control | Operator learning curve |
| Bitnami Helm chart | Apache-2.0 (images changed distribution terms in 2025) | Quick | Weak day-2 operations; image availability risk |
| Confluent for Kubernetes | Proprietary | Enterprise features | Not open source |
| Redpanda | BUSL-1.1 | Fast, simple | Not open source; not Kafka itself |

## Decision

Use **Strimzi** with **KRaft** and `KafkaNodePool`s. In `dev`, run **three small
combined-role (controller + broker) pods on two nodes** with **replication factor 3 and
`min.insync.replicas=2`**; producers use `acks=all` and idempotence. Larger profiles
separate controller and broker pools.

## Consequences

- One broker can fail without losing acknowledged writes or availability, even in `dev`.
- Combined mode is a local compromise; production-like profiles use dedicated controllers.
- Kafka and Strimzi upgrades become explicit Phase 8 scenarios (operator first, then
  Kafka version, then metadata version).
