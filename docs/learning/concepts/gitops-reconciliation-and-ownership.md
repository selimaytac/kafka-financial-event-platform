# GitOps reconciliation and resource ownership

Applied in [ADR 0028](../../adr/0028-use-cilium-as-cni-with-bootstrap-and-adopt.md) and
[ADR 0030](../../adr/0030-generate-applications-with-applicationsets.md).

## What reconciliation is

A GitOps controller runs a loop: read the desired state from Git, read the actual state
from the cluster, and act on the difference. Push-based deployment (a pipeline runs
`kubectl apply`) acts once; reconciliation acts continuously, so manual changes are
detected (drift) and, with self-heal, reverted.

```
Git (desired) ──► controller ──► compare ──► cluster (actual)
                      ▲                          │
                      └──────── watch ───────────┘
```

Consequence: Git becomes the only change path. An emergency change made by hand is
reverted unless it is also committed.

## Single writer

Every resource must have exactly one owner. Two controllers that both consider a resource
theirs revert each other's changes indefinitely ("fighting controllers"). Typical
sources: an IaC tool and a GitOps controller managing the same Helm release; two Argo CD
Applications rendering the same object; an operator and a GitOps tool both setting a field.

## The bootstrap problem, again

The GitOps controller cannot install what it needs in order to run. On Kubernetes, the
CNI is the clearest case: without it no pod starts, including the controller. The pattern
**bootstrap and adopt** resolves it:

1. An imperative or IaC step installs the prerequisite once.
2. The GitOps controller starts and takes ownership of the same objects from Git.
3. The first installer stops managing them (e.g. `ignore_changes`), so there is one writer.

Both steps must render identical manifests, ideally from the same files, or the adoption
itself shows up as a change.

## Deterministic rendering

A controller compares rendered manifests with the cluster. If rendering is not
deterministic (random names, generated certificates, timestamps), every comparison finds
a difference and the application never settles. Such values must be generated in the
cluster (e.g. by a Job) or excluded from comparison.

## How to decide

1. For each resource, name its single owner and the path by which it changes.
2. Identify prerequisites the GitOps controller needs; bootstrap exactly those, then adopt.
3. Check rendering is deterministic before enabling automated sync.
4. Decide what deletion means: should removing a directory uninstall a component, or
   leave it running until removed deliberately?
