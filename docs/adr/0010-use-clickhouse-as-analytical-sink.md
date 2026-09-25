# 0010. Use ClickHouse (Altinity operator) as the analytical sink

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Processed events feed OHLCV candles, trade analytics and the audit trail. The store must
ingest hundreds of thousands of rows per second, compress well (disk budget) and answer
aggregate queries quickly for Grafana.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| ClickHouse + Altinity operator | Apache-2.0 | Columnar, very high ingest, strong compression, Kafka-friendly, Grafana plugin | Eventual merges; updates/deletes are expensive |
| PostgreSQL / TimescaleDB | PostgreSQL / Timescale License (TSL for some features) | Transactions, familiar | Lower ingest at this rate; TSL not OSI |
| Apache Druid / Pinot | Apache-2.0 | Real-time OLAP | Many components, heavy for a single host |

## Decision

Use **ClickHouse** managed by the **Altinity clickhouse-operator**.

## Consequences

- Append-only tables suit an audit trail; immutability controls are designed in Phase 4.
- Backup/restore (e.g. clickhouse-backup) and version upgrades are Phase 7/8 scenarios.
- Deduplication relies on idempotent keys and engine choice, documented per table.
