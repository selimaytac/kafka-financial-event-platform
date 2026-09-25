# 0002. Define "one billion events" as cumulative throughput

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The headline goal is "a platform that handles one billion events". That can mean storing
one billion events or processing them. The development machine has ~76 GB of free disk:
one billion ~200-byte records is ~200 GB raw before replication (RF=3 ⇒ ~600 GB), which
cannot be stored locally. Real exchange platforms are also sized by sustained
throughput and latency, not by how much sits in the broker.

## Options

| Option | Pros | Cons |
|---|---|---|
| Store 1B events in Kafka | Impressive single number | Impossible within disk budget; not how brokers are used |
| Process 1B events cumulatively in one measured run | Realistic, measurable, fits resources | Needs a disciplined benchmark method |
| Process 1B events across many runs | Easy | Hides sustained-throughput behaviour |

## Decision

"One billion" means **one billion events produced, processed end-to-end and accounted
for in a single sustained run** (target order of magnitude ~100k msg/s ≈ 3 h).
Kafka retention is capped by size and time; downstream stores keep aggregates and
audit data, not every raw tick.

## Consequences

- A benchmark method (`docs/benchmarks/`) must define counting, loss detection and
  end-to-end reconciliation (produced = consumed = sunk).
- Topic retention is designed per data class (see compliance ADRs later), not "keep all".
- The run happens on the `perf` profile ([0003](0003-layered-portable-provisioning.md)),
  provisioned for the run and torn down afterwards.
