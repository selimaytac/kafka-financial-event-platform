# 0003. Layered, portable provisioning with environment profiles

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The platform must run on a single development host today, within a modest memory budget,
and be movable to an on-prem hypervisor or a cloud later without a
rewrite. Some scenarios (billion-event run, DR site) need far more resources than can
run daily, but must still exist as working, reviewable code. Every environment must be
a *provisioned state*: reproducible from the repository, never hand-built.

## Options

| Option | Pros | Cons |
|---|---|---|
| One flat setup tied to the local tool | Fastest start | Not portable; big scenarios can't coexist with daily use |
| Layered: substrate module → bootstrap → GitOps, with profiles | Portable, only one layer knows the substrate; profiles size the same platform differently | More structure up front |
| Separate repos per environment | Strong isolation | Duplication and drift |

## Decision

Three layers, each with one responsibility:

| Layer | Responsibility | Tool | Substrate-aware? |
|---|---|---|---|
| 0 · Substrate | Create nodes/cluster, output a kubeconfig | OpenTofu module per provider | Yes (only this layer) |
| 1 · Bootstrap | Install the GitOps controller and point it at the repo | OpenTofu | No |
| 2 · Platform & apps | Everything else, declaratively | Argo CD + Kustomize overlays | No |

Profiles size the same platform:

| Profile | Purpose | Lifecycle |
|---|---|---|
| `dev` | Daily development, small footprint | Runs routinely |
| `perf` | Billion-event run, tuning, benchmarks | Provisioned on demand, destroyed after |
| `dr` | Secondary site for disaster-recovery drills | Provisioned on demand, destroyed after |

## Consequences

- Adding a substrate = adding one Layer 0 module; nothing above it changes.
- HA/DR designs can be complete and tested as drills without running continuously.
- `destroy` + `apply` is a normal operation and doubles as a rebuild test.
- Each component must be profile-aware (replicas, resources) through overlays.
