# Runbook: create, rebuild and remove a cluster

| Field | Value |
|---|---|
| Component | Foundation, substrate, bootstrap stacks |
| Trigger | New workstation; daily start/stop; cluster broken beyond quick repair |
| Impact if ignored | No environment to work in |
| Risk of the procedure | Low (`dev`); cluster data is not preserved by a rebuild |

## Preconditions

- Docker running with at least 8 GB memory; `task tools:check` passes.
- Secret zero available: macOS Keychain entry, or `TOFU_STATE_PASSPHRASE` exported.

## Steps

### First time on a machine

1. `task secrets:init`: creates secret zero if missing. **Store a copy in a password
   manager**; see [secret zero backup](secret-zero-backup-and-restore.md).
2. `task foundation:apply`: state store container, then the state bucket. Review both plans.

### Create or update a cluster

1. `task cluster:up PROFILE=dev`: shared load balancer, kind cluster, Cilium, Argo CD and
   the root Application, each after reviewing its plan.
   Use `REVISION=<branch>` only while testing an unmerged branch.
2. `export KUBECONFIG=~/.kube/kfep-dev.yaml`

### Remove a cluster

1. `task cluster:down PROFILE=dev`: bootstrap first, then the substrate (reverse order).
   The state store and its data are not touched.

## Rollback

`cluster:up` and `cluster:down` are each other's rollback. State history is kept by
bucket versioning.

## Verification

- `kubectl get nodes`: all `Ready`.
- `kubectl -n argocd get applications`: every Application `Synced` and `Healthy`.
- `task tofu STACK=bootstrap PROFILE=dev -- plan`: `No changes`.
