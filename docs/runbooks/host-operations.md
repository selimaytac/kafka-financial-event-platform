# Runbook: pause, recover and remove the lab on its host

| Field | Value |
|---|---|
| Component | Whole lab ([ADR 0034](../adr/0034-run-the-lab-as-a-guest-on-its-host.md)) |
| Trigger | Freeing host resources, Docker stopped or reset, lost state data, decommissioning |
| Impact if ignored | Resource contention on the host, or an unrecoverable lab |
| Risk of the procedure | L0–L2 low; L3 medium; L4 destructive by design |

## Preconditions

- Secret zero available ([backup runbook](secret-zero-backup-and-restore.md)).
- Only objects of this lab are touched: kind clusters `kfep-*`, containers labelled
  `platform-labs.component`, load balancers `kindccm-*`.

## Steps

| Level | Situation | Command | Measured |
|---|---|---|---|
| L0 | Free resources on the host | `task lab:stop` | ~1.5 min (API server drains watches) |
| L0/L1 | Resume, also after Docker was quit | `task lab:start` | ~7 s to nodes Ready |
| L2 | Docker was reset or pruned | `task lab:restore PROFILE=dev` | 280 s to all Applications Synced/Healthy |
| L3 prevention | Before risky changes, periodically | `task lab:backup` (state store and OpenBao data, ADR 0040) | seconds; archive in `~/platform-labs-backups/` |
| L3 | State data directory lost or corrupted | `task lab:restore-state -- <archive>`, then `task foundation:apply` | 33 s |
| L4 | Remove the lab from the machine | `task lab:purge` (asks for confirmation) | — |

Drill for L2 without touching other Docker objects: `task lab:drill:docker-reset`, then
`task lab:restore PROFILE=dev`.

### Circuit breaker during starts

Pod limits protect nodes, not the host. Run `task lab:guard` in a second terminal before
`lab:start`, `cluster:up` or enabling addons. It measures an idle baseline (30 s), then
stops this lab's kind nodes (`docker kill`) when any trigger holds for two samples:

| Trigger | Default | Override |
|---|---|---|
| Kernel memory pressure (macOS: 1 normal, 2 warn, 4 critical) | critical | `GUARD_MAX_PRESSURE` |
| Free memory | below 10 % | `GUARD_MIN_FREE_PCT` |
| Swap growth since baseline | above 3072 MB | `GUARD_SWAP_GROWTH_MB` |
| Load average above baseline | off | `GUARD_LOAD_DELTA` (e.g. 3/4 of the CPUs) |

Swap growth and load average alone proved noisy on macOS: swap grows while RAM is still
free, and unrelated host processes spike the load. Memory pressure is the kernel's own
"about to stall" signal.

It runs for 30 minutes (`GUARD_DURATION`) and logs to `guard.log` in the lab data
directory. After a trip: free host memory first, then `task lab:start`, or start lighter
([0039](../adr/0039-keep-dev-light-with-core-and-addon-components.md)).

## Rollback

- L3 keeps the replaced data as `seaweedfs.before-restore-<timestamp>` (and
  `openbao.before-restore-<timestamp>`) and the replaced foundation state files with the
  same suffix. OpenBao data is only usable with the seal key in the restored state.
- L4 has no rollback except restoring a backup together with secret zero.

## Verification

- `task lab:status`: expected containers present and running.
- `task foundation:plan` and `task tofu STACK=<stack> [PROFILE=<p>] -- plan`: `No changes`.
- `kubectl -n argocd get applications`: all `Synced` and `Healthy`.
