# 0012. Use Apicurio Registry for event schemas

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Events cross team and service boundaries; a malformed or silently changed event in the
order flow is an incident. Schemas must be versioned, compatibility-checked and
enforced at produce time.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| Apicurio Registry | Apache-2.0 | Avro/Protobuf/JSON Schema, compatibility rules, Confluent-compatible API | Fewer tutorials |
| Confluent Schema Registry | Confluent Community License | De-facto standard | Not OSI open source |
| Karapace | Apache-2.0 | Confluent API compatible | Smaller project |

## Decision

Use **Apicurio Registry** with backward-compatibility rules enforced per subject.
The serialization format (Avro vs Protobuf) is decided with the event model in Phase 4.

## Consequences

- Schema evolution becomes a reviewed change with compatibility checks.
- Schemas can carry data-classification metadata (PII tags) for governance.
