# 0034. Run the lab as a guest on its host: minimal footprint, explicit start, graded recovery

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The lab runs on hosts it does not own exclusively (a developer machine, a homelab node, a VM),
and Docker may be stopped or reset independently of it. Anything the lab changes on the host can collide with other
tools or with the host's security policy. In particular, a trusted root CA whose private
key sits in lab state would let anyone holding that key impersonate any website to this
machine.

## Options

| Concern | Option | Trade-off |
|---|---|---|
| Entry point | Port 443 | Privileged, likely in use by other tools |
| | **127.0.0.1 on a lab-specific high port** | Non-standard URL port |
| Autostart | `unless-stopped` | Lab consumes resources whenever Docker starts |
| | **`restart = no`; explicit `task lab:start`** | One extra command |
| TLS trust | Trust the lab CA system-wide | Large blast radius if the key leaks |
| | **Name-constrained CA, not trusted by default; optional, reversible user-level trust** | Browser warnings unless opted in |
| Shared tool paths | `~/.terraform.d/plugin-cache` | May belong to other tools |
| | **Lab-owned directories only** | Duplicate provider downloads |

## Decision

- Lab endpoints bind to 127.0.0.1 on high ports; lab containers do not restart on their own.
- The lab CA is name-constrained to `kfep.localhost` and is not added to any trust store by
  default.
- All host footprint is inventoried in [host-footprint](../operations/host-footprint.md) and
  handled by graded procedures ([host operations runbook](../runbooks/host-operations.md)):

| Level | Event | Procedure |
|---|---|---|
| L0 | Pause the lab | `task lab:stop` / `task lab:start` |
| L1 | Docker quit | `task lab:start` |
| L2 | Docker reset | `task lab:restore PROFILE=dev` (state data lives on a host bind mount) |
| L3 | State data lost | `task lab:restore-state -- <archive>` from `task lab:backup` |
| L4 | Remove the lab | `task lab:purge` |

## Consequences

- Measured: L2 recovery (lab-only reset to all Applications Synced/Healthy, including image
  pulls) 280 s; L3 restore 33 s with every plan clean afterwards; a drill left non-lab
  containers untouched.
- Found during drills and fixed: the kind provider errors instead of re-creating a missing
  cluster (handled in `cluster:up`); manual-sync components need an explicit adoption sync
  after bootstrap (`task argo:adopt`); the default 10 s stop timeout killed etcd and the
  state store (now 120 s / 30 s, since the API server needs ~90 s to drain watches).
