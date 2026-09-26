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
| L3 prevention | Before risky changes, periodically | `task lab:backup` | seconds; archive in `~/platform-labs-backups/` |
| L3 | State data directory lost or corrupted | `task lab:restore-state -- <archive>`, then `task foundation:apply` | 33 s |
| L4 | Remove the lab from the machine | `task lab:purge` (asks for confirmation) | — |

Drill for L2 without touching other Docker objects: `task lab:drill:docker-reset`, then
`task lab:restore PROFILE=dev`.

## Rollback

- L3 keeps the replaced data as `seaweedfs.before-restore-<timestamp>` and the replaced
  foundation state files with the same suffix.
- L4 has no rollback except restoring a backup together with secret zero.

## Verification

- `task lab:status`: expected containers present and running.
- `task foundation:plan` and `task tofu STACK=<stack> [PROFILE=<p>] -- plan`: `No changes`.
- `kubectl -n argocd get applications`: all `Synced` and `Healthy`.
