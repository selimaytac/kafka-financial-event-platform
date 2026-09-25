# Benchmarks

Goal: one billion events processed end-to-end in a single sustained run
([ADR 0002](../adr/0002-define-billion-as-cumulative-throughput.md)).

## Method (baseline, refined in Phase 6)

| Aspect | Rule |
|---|---|
| Counting | Producer counts acknowledged events; processor and sink count per partition |
| Correctness | Reconciliation: produced = processed = stored, no duplicates, no gaps |
| Metrics | Throughput (msg/s, MB/s), end-to-end latency p50/p99/p999, consumer lag, CPU/memory/disk |
| Environment | Hardware, profile, versions and configuration recorded with each result |
| Caveat | kind shares one host's disk and kernel; results are indicative, not production numbers |

## Results

| Date | Profile | Events | Duration | Avg throughput | p99 latency | Report |
|---|---|---|---|---|---|---|
| _none yet_ | | | | | | |
