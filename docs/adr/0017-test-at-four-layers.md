# 0017. Test at four layers: application, infrastructure, load, chaos

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

A finance platform must show evidence, not claims: exactly-once holds, policies block
what they should, throughput targets are met, and failures are survived. Each concern
needs a different kind of test.

## Options

Per layer, the chosen tool and the main alternative considered:

| Layer | Chosen | Alternative | Why chosen |
|---|---|---|---|
| App unit + integration | Go `testing` + testcontainers-go | Mocks only | Real Kafka/ClickHouse in tests catches protocol and EOS issues |
| Manifest / infra | kubeconform, Kyverno CLI, Chainsaw | Manual review | Schema, policy and end-to-end cluster behaviour tested in CI |
| Load / performance | k6 + xk6-kafka, `kafka-producer-perf-test` | JMeter | Scriptable, CI-friendly; Kafka's own tool as baseline |
| Chaos | Chaos Mesh | Litmus | CNCF, CRD-driven, fits GitOps; strong pod/network/IO faults |

## Decision

Adopt all four layers. A phase is not done until its tests exist at the relevant layers.

## Consequences

- k6 is AGPL-3.0: used as a tool, not embedded; noted for awareness.
- Chaos experiments double as HA/DR drill evidence (Phase 7).
- Load tests run on the `perf` profile; `dev` runs smoke-sized versions.
