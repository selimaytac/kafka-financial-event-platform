# High availability and disaster recovery

Scenarios are designed as code and exercised as drills; they do not all run at the
same time ([ADR 0003](../adr/0003-layered-portable-provisioning.md)).
RPO = maximum acceptable data loss; RTO = maximum acceptable time to recover.

## Scenario catalogue

| ID | Scenario | Type | Expected behaviour | Target RPO / RTO | Profile | Status |
|---|---|---|---|---|---|---|
| HA-01 | One Kafka broker pod killed | HA | Leaders move; no acknowledged write lost | 0 / < 1 min | `dev` | planned |
| HA-02 | Worker node lost | HA | Pods reschedule; Kafka stays available with min ISR | 0 / < 5 min | `dev` | planned |
| HA-03 | Network partition between brokers | HA | Minority side stops accepting writes; no split brain | 0 / after heal | `dev` | planned |
| HA-04 | Matching engine crash mid-transaction | HA | Transaction aborted; engine resumes from last commit; no duplicate or missing executions | 0 / < 1 min | `dev` | planned |
| HA-05 | Valkey loss | HA | Dedup falls back to sink idempotency; cache rebuilt | 0 / < 5 min | `dev` | planned |
| HA-06 | ClickHouse replica loss | HA | Inserts continue on remaining replica | 0 / < 5 min | `perf` | planned |
| DR-01 | Full cluster loss, restore from backup | DR | Rebuild from Git + restore data | TBD (rebuild without data measured: ~3 min, Phase 1) | `dr` | planned |
| DR-02 | Site failover to secondary cluster | DR | Consumers resume on secondary from replicated offsets | TBD | `dr` | planned |
| DR-03 | Accidental topic or table deletion | DR | Restore from backup; GitOps recreates config | TBD | `dev` | planned |
| DR-04 | Bad deployment (config or schema) | DR | Git revert; Argo CD rolls back | 0 / < 10 min | `dev` | planned |
| DR-06 | Host Docker reset (lab only) | DR | Rebuild from code; state survives on the host bind mount | 0 / 280 s measured | `dev` | verified |
| DR-07 | State store data lost | DR | Restore archive from `task lab:backup` | Since last backup / 33 s measured | `dev` | verified |
| DR-05 | Order book state lost | DR | Rebuild from snapshot + log replay; book identical to pre-failure (checksum) | 0 / TBD | `dev` | planned |

Targets marked TBD are decided with the DR topology decision in Phase 7.
Each drill produces a report: steps, timings, measured RPO/RTO, findings.
