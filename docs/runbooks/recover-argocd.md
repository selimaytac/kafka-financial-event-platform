# Runbook: recover Argo CD after a bad change

> **Not yet exercised.** Step 3 is scheduled as a Phase 7 drill; until then treat it as a design.

| Field | Value |
|---|---|
| Component | Argo CD (self-managed) |
| Trigger | Argo CD UI/API down, or Applications stop syncing after a change under `gitops/` |
| Impact if ignored | No reconciliation: drift is not corrected, new changes are not deployed |
| Risk of the procedure | Medium: step 3 reinstalls Argo CD in place |

## Preconditions

- `KUBECONFIG` points at the affected cluster; access to the repository.

## Steps

1. Identify the change: `git log -- gitops/` and `kubectl -n argocd get pods`.
2. Revert it through a pull request. If Argo CD still reconciles, it applies the revert.
3. If Argo CD cannot reconcile at all, re-install it from the reverted Git state:
   `task tofu STACK=bootstrap PROFILE=<profile> -- apply -replace=helm_release.argocd`
   (the release has `ignore_changes`, so a plain apply would not touch it).
4. Wait for the `argocd` Application to report `Synced` and `Healthy`; Argo CD then owns
   itself again.

## Rollback

Step 3 is itself a reinstall from Git; if it fails, rebuild the cluster
([cluster lifecycle](cluster-lifecycle.md)).

## Verification

- `kubectl -n argocd get applications`: all `Synced` and `Healthy`.
- Delete a managed Deployment in a test namespace and confirm it is restored (self-heal).
