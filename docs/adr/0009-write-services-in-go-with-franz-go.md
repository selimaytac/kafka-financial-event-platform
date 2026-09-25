# 0009. Write services in Go with franz-go

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Several services are needed: a load generator of synthetic traders, order entry with
pre-trade risk checks, the matching engine, market data, surveillance and post-trade
processing. They must be fast, small, easy to containerise and support Kafka transactions.

## Options

| Option | Pros | Cons |
|---|---|---|
| Go + franz-go | Pure Go (no cgo), full protocol incl. transactions (EOS), very high throughput, BSD-3 | Smaller community than librdkafka |
| Go + confluent-kafka-go | Wraps librdkafka, widely used | cgo, cross-compilation friction |
| Java + Kafka Streams | Reference client, rich stream processing | Heavier runtime and images |

## Decision

Services are written in **Go** using **franz-go**.

## Consequences

- Static binaries and small distroless images; arm64 and amd64 builds are trivial.
- Exactly-once uses franz-go's transactional session; semantics must be proven by tests.
- Go toolchain is needed from Phase 4.
