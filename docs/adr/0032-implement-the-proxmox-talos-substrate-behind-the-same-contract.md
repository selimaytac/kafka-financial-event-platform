# 0032. Implement the Proxmox + Talos substrate behind the same output contract

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

[ADR 0005](0005-design-proxmox-talos-as-second-substrate.md) chose Proxmox VE with Talos
Linux as the second substrate, designed as code and run on demand. Portability
([0003](0003-layered-portable-provisioning.md)) is only credible if the bootstrap and GitOps
layers work unchanged on it. Writing the module surfaced one real limit: Cilium needs
Talos-specific settings (Talos mounts cgroups itself and restricts capabilities).

## Options

| Concern | Option | Trade-off |
|---|---|---|
| Talos image | Fixed vanilla image URL | Magic constant; no guest agent |
| | **Image Factory schematic resource with the QEMU guest agent extension** | Declarative; image identity derived from its contents |
| Node addressing | DHCP | Unknown addresses at apply time |
| | **Static IPs via the nocloud cloud-init drive** | Machine configuration can target known addresses |
| Substrate differences in Layer 2 | Separate GitOps trees per substrate | Duplication; drift between trees |
| | **One `values-substrate-<type>.yaml` per component, selected by the root Application** | Differences are isolated in one named file |

## Decision

- `infra/modules/proxmox-talos-cluster` creates VMs with bpg/proxmox, boots the Talos
  nocloud ISO from the Image Factory, applies machine configuration with the Talos provider
  (CNI disabled, as on kind), bootstraps etcd and writes a dedicated kubeconfig.
- `infra/stacks/substrate-proxmox` exposes the same outputs as `substrate-kind`, plus
  `substrate = "talos"`. Proxmox credentials come only from the environment
  (`PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`), never from code or state.
- The substrate type is part of the output contract; the root Application adds
  `values-substrate-<type>.yaml` to every component's values.

## Consequences

- The stack is validated in CI but **has never been applied**. To confirm on the first
  real run: the Talos client configuration encoding (decoded as base64), install disk
  name, and Cilium's Talos values.
- A single control-plane node has no etcd quorum; three are needed for control-plane HA.
- TLS and a least-privilege Proxmox API token become mandatory on a real network
  (known limits of [0025](0025-store-iac-state-in-out-of-cluster-seaweedfs.md) revisited).
