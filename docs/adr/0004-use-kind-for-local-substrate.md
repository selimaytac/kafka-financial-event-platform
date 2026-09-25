# 0004. Use kind as the local substrate with a two-node dev profile

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Layer 0 ([0003](0003-layered-portable-provisioning.md)) needs a local Kubernetes that runs
on macOS (Apple Silicon) inside Docker, is conformant, supports multiple nodes (to model
node failure) and can be driven from OpenTofu. An initial sketch used one control-plane
plus three workers; given that only about half of the 18 GB is free, the daily footprint
was reduced.

## Options

| Option | Pros | Cons |
|---|---|---|
| kind | Upstream Kubernetes (used by Kubernetes' own CI), multi-node, OpenTofu provider, `cloud-provider-kind` for LoadBalancers | Nodes are containers; no real kernel isolation |
| k3d (k3s) | Lighter, fast | k3s differs from upstream (bundled components) |
| minikube | Mature, many drivers | Multi-node is secondary; heavier |
| Docker Desktop k8s | Zero setup | Single node, not scriptable as IaC |

## Decision

Use **kind**. The `dev` profile is **1 control-plane + 1 worker**. Larger profiles
(`perf`, `dr`) add workers and are created only when needed.

## Consequences

- Node-failure scenarios exist even in `dev` (drain/stop the worker).
- Pod anti-affinity must be *preferred*, not *required*, in `dev` so three Kafka pods fit
  on two nodes ([0008](0008-run-kafka-with-strimzi-in-kraft-mode.md)).
- kind nodes share the host kernel and disk: I/O numbers are indicative, not
  production-representative; benchmarks must state this.
