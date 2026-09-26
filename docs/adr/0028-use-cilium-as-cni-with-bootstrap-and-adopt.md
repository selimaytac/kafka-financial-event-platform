# 0028. Use Cilium as the CNI on every substrate, installed with bootstrap-and-adopt

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The CNI provides pod networking and enforces NetworkPolicy. Micro-segmentation (which
workload may talk to which) is an expected control in financial systems. NetworkPolicies
live in the substrate-agnostic GitOps layer ([0003](0003-layered-portable-provisioning.md)),
so they must behave the same on every substrate. Without a CNI, nodes stay `NotReady` and
no pod runs, including the GitOps controller.

## Options

| Option | Pros | Cons |
|---|---|---|
| kindnet (kind default) | Built in, very light; basic L3/L4 NetworkPolicy since kind v0.24 | Exists only on kind; policy semantics would change on other substrates; no flow visibility |
| **Cilium** | Same CNI on kind, Proxmox/Talos and cloud; L3/L4 and L7, identity-based policy; Hubble flow observability; CNCF graduated | Extra memory (agent per node, operator); installed separately |
| Calico | Mature, widely used | Adds a second policy dialect to learn; weaker built-in flow observability |

## Decision

Use **Cilium** on all substrates. kind is created with its default CNI disabled.
Installation follows **bootstrap-and-adopt**: the bootstrap stack (Layer 1) installs Cilium
with Helm because nothing else can run before it; Argo CD then manages the same release
from Git, so later changes and upgrades are GitOps changes.

kube-proxy stays enabled initially; Cilium's kube-proxy replacement is a later, separate change.

## Consequences

- Bootstrap order: cluster → Cilium → Argo CD → Argo CD adopts Cilium.
- The Helm values used at bootstrap and in GitOps must match, or Argo CD will report drift.
- NetworkPolicies can be tested identically on every substrate; Hubble provides evidence
  for segmentation controls.
