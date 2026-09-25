# 0011. Use Valkey for deduplication and last-price cache

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Order entry needs a fast key-value store for idempotency keys (rejecting resubmitted
orders within a window) and for the latest price per instrument used by pre-trade
price checks and market data.
Redis changed its license in 2024 (RSAL/SSPL) and added AGPL-3.0 as an option in 2025.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| Valkey | BSD-3-Clause (Linux Foundation) | Redis-compatible fork, permissive, active | Newer brand |
| Redis 8 | RSALv2 / SSPLv1 / AGPLv3 | Original project | Copyleft or source-available terms |
| Dragonfly | BSL-1.1 | Very fast | Not open source |
| No cache (ClickHouse only) | — | Fewer components | Too slow for per-event dedup |

## Decision

Use **Valkey**.

## Consequences

- Dedup window and TTLs become explicit, documented parameters.
- Cache loss must be survivable: Kafka + ClickHouse remain the source of truth.
- Valkey HA (replica + Sentinel) is evaluated in Phase 7.
