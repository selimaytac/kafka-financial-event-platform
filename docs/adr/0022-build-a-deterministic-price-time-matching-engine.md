# 0022. Build a deterministic price-time priority matching engine on Kafka

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

An exchange is defined by its matching engine. Simulating trades directly would skip the
order book, and with it replay, surveillance and exactly-once processing, which are the
core learning goals. A full production engine (auctions, hidden and stop orders) is out of
scope.

## Options

| Option | Pros | Cons |
|---|---|---|
| Simple but real engine: price-time priority, limit/market, cancel/modify | Real order book; deterministic replay; realistic event volume | Needs careful design and tests |
| No engine, simulator emits trades | Very simple | No order book, weak replay and surveillance story |
| Full engine (auctions, hidden, stop orders) | Most realistic | Scope dominates the platform work |

## Decision

Build a **simple, deterministic price-time priority engine** in Go:

- Orders are keyed by instrument; each partition is processed by **one single-threaded
  engine loop**, so ordering per instrument is guaranteed by Kafka.
- The engine is a pure function of its input log: replaying the same orders yields the same
  book, trades and sequence numbers.
- Read-process-write uses **Kafka transactions**: consuming an order and emitting its
  executions and book updates commit atomically.
- Order book state is snapshotted periodically; recovery = latest snapshot + replay of
  the log after it.

Pipeline stages (exact service split decided in Phase 4):

```
order entry + pre-trade risk ─► orders ─► matching engine ─► executions, book updates
                                                  ├─► market data (L1/L2, OHLCV) ─► ClickHouse
                                                  ├─► surveillance (MAR patterns)
                                                  └─► post-trade (positions, T+2) + audit
```

## Consequences

- Throughput scales with partitions/instruments, not threads per instrument; a single hot
  instrument is bounded by one engine loop (documented as a known limit).
- Deterministic replay is a correctness test *and* a DR mechanism (rebuild the book from
  the log), and it constrains topic retention: the log since the last snapshot must be kept.
- Wall-clock time must not influence matching; timestamps come from the order events.
