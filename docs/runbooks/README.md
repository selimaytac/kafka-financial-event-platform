# Runbooks

Operational procedures, one file per task. Written for someone on call who has not seen
the system before. Start from [template.md](template.md).

| Runbook | Component | Trigger |
|---|---|---|
| [Create, rebuild and remove a cluster](cluster-lifecycle.md) | Foundation, substrate, bootstrap | New machine, daily use, broken cluster |
| [Recover Argo CD after a bad change](recover-argocd.md) | Argo CD | Argo CD down or not syncing |
| [Back up and restore secret zero](secret-zero-backup-and-restore.md) | State encryption | Initial setup, new machine, exposure |
