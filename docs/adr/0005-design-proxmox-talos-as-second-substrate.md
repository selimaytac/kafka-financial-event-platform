# 0005. Design Proxmox + Talos Linux as the second substrate

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Portability ([0003](0003-layered-portable-provisioning.md)) is only proven by a second
Layer 0 implementation. Banks and exchanges commonly run on-prem (data-locality and
regulatory expectations), so an on-prem virtualised target is more representative of the
domain than a public cloud. The module is designed and kept valid as code; it is run
on demand when a Proxmox host is available.

## Options

| Option | Pros | Cons |
|---|---|---|
| Proxmox VE + Talos Linux | On-prem, typical of regulated finance; Talos is immutable, API-driven, no SSH, fully declarative; good OpenTofu providers (`bpg/proxmox`, `siderolabs/talos`) | Needs a Proxmox host to execute |
| Proxmox + Ubuntu + kubeadm | Familiar | Mutable OS, config drift, more maintenance |
| Managed cloud (EKS/GKE) | Real LBs and disks | Cost; less representative of on-prem finance |

## Decision

The second substrate is **Proxmox VE with Talos Linux**, provisioned by OpenTofu
(`bpg/proxmox` for VMs, `siderolabs/talos` for machine config and bootstrap).
Output contract matches kind's module: a kubeconfig. Cloud remains a possible third target.

## Consequences

- Layer 0 modules share an output contract (kubeconfig, cluster name, node list).
- Talos upgrades are image-based, which feeds the upgrade scenarios in Phase 8.
- Module validity is checked in CI with `tofu validate` even when not applied.
