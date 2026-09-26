# Phase 1 retrospective: cluster

**Goal:** a cluster that is created, bootstrapped and handed to GitOps entirely from code,
on a local substrate, with a second substrate designed behind the same contract.

**Result:** `task cluster:up PROFILE=dev` builds kind, Cilium and a self-managing Argo CD
in about three minutes; `cluster:down` removes it in about half a minute. State lives
outside the clusters, encrypted, locked and versioned.

## Lessons

### 1. Write acceptance criteria before the spike

The state store was chosen by a time-boxed experiment with criteria written in advance
(locking, versioning, encryption, footprint). "S3-compatible" turned out to be a spectrum:
one candidate accepted conditional writes without honouring them, so two concurrent runs
both "held" the lock, with no error. Safety mechanisms need negative tests: prove they
fail when they should ([ADR 0025](../../adr/0025-store-iac-state-in-out-of-cluster-seaweedfs.md)).

### 2. Test the test

The first lock test passed nothing and failed both candidates, because the resource used
to hold the lock never actually ran: changing `terraform_data.input` updates in place,
while provisioners run only on create. Only the debug log showed it. A surprising result
is a prompt to verify the measurement before the conclusion.

### 3. Anything a plan depends on must be known at plan time

Twice the same rule appeared in different forms:

- A provider configured with credentials that a resource generates in the same run cannot
  plan; the dependency was split across two stacks.
- A Kubernetes custom resource cannot be planned before its CRD exists; the root
  Application is rendered through a Helm chart instead of a typed manifest.

When a configuration refers to something that only exists after apply, move the boundary.

### 4. Tags move; digests do not

Container image tags were re-pushed upstream with new contents (the kind node image for the
same Kubernetes version now has a different digest). The same holds for Git tags of CI
actions and hooks. Everything third-party is pinned by content: SHA for code, digest for
images, hashes for providers ([ADR 0029](../../adr/0029-pin-kubernetes-through-the-kind-provider.md)).

### 5. GitOps needs deterministic rendering

A chart that generates certificates on every render leaves the controller permanently
out of sync. Generate such values in the cluster, or exclude them from comparison.

### 6. One writer per resource

The installer that bootstraps a component and the controller that adopts it must not both
manage it. Verified two ways: a manual deletion was restored by Argo CD, and a new plan of
the bootstrap stack showed no changes ([ADR 0030](../../adr/0030-generate-applications-with-applicationsets.md)).

### 7. Cardinality and lifecycle choose the stack

The load-balancer controller for kind serves every cluster on a Docker host, so it lives in
a profile-less stack; per-cluster placement would have run two controllers over the same
clusters. Where a resource goes follows from how many of it exist and when it changes.

### 8. Portability has limits; name them

The CNI needs substrate-specific settings on Talos. Instead of forking the GitOps tree,
differences live in one file per component (`values-substrate-<type>.yaml`), and the
substrate type is part of the output contract
([ADR 0032](../../adr/0032-implement-the-proxmox-talos-substrate-behind-the-same-contract.md)).

### 9. Fix the class of error, not the instance

- Validation with the backend disabled tried to read encrypted local state without its
  encryption settings; validation now runs on a copy without state.
- A provider lock file was missing from a commit, and CI would have created one silently;
  a check now fails when a lock file is absent.

### 10. Bring existing resources under management by import, and expect zero diff

Repository settings and branch protection created by hand were imported with `import`
blocks. The first plan must show imports and no changes to the real objects; anything
else means the code does not describe reality yet
([ADR 0031](../../adr/0031-manage-repository-settings-as-code.md)).

### 11. Measure rebuild time

A full rebuild takes about three minutes without data. That number is the lower bound of
recovery time and an input to the DR targets in Phase 7.

## Carried forward

| Item | Where |
|---|---|
| Apply the Proxmox + Talos stack on a real host; confirm the assumptions listed in ADR 0032 | When a host is available |
| Exercise the Argo CD recovery runbook | Phase 7 drill |
| Kubernetes 1.35 → 1.36 → 1.37 | Phase 8 |
| TLS for the state store; replace the Docker socket mount for the kind load balancer where possible | Phase 2 / Proxmox |
| Expose Argo CD and Hubble through the Gateway with authentication | Phase 2 |
