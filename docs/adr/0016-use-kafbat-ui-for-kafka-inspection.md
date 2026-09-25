# 0016. Use Kafbat UI for Kafka inspection

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Operators need to browse topics, consumer groups, lag, schemas and ACLs without shell
access to brokers.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| Kafbat UI | Apache-2.0 | Community continuation of provectus/kafka-ui, schema registry support, RBAC | Community-maintained |
| AKHQ | Apache-2.0 | Mature | Less active UI development |
| Redpanda Console | BUSL-1.1 (parts) | Polished | Not fully open source |

## Decision

Use **Kafbat UI**, exposed through the Gateway with authentication and read-only
defaults.

## Consequences

- UI access is itself an access-control concern (who can read order flow) and is
  covered by the control matrix.
