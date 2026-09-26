# 0025. Store IaC state in out-of-cluster SeaweedFS with locking, versioning and encryption

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

OpenTofu state maps code to real resources and contains credentials (for example the
cluster admin kubeconfig). It needs durable storage, locking against concurrent runs,
versioning to recover from corruption, and encryption at rest. It must live **outside**
the clusters it describes: a cluster cannot hold the state that creates it, and deleting
a cluster must not delete its state. The same out-of-cluster store will later hold
backups for disaster recovery. Background: [OpenTofu state](../learning/concepts/opentofu-state.md).

A time-boxed spike tested S3-compatible stores against acceptance criteria written in
advance (OpenTofu 1.12.6, `use_lockfile = true`):

| Criterion | SeaweedFS 4.47 | Garage v2.4.1 |
|---|---|---|
| `tofu init` with S3 backend | Pass | Pass |
| Concurrent run rejected (lock via conditional write `If-None-Match`) | Pass | **Fail, silently**: the header is ignored, both runs acquire the lock |
| Object versioning, restore of an older state version | Pass | Not implemented |
| State unreadable at rest (OpenTofu client-side encryption) | Pass | Pass |
| Idle memory | ~118 MiB | ~4 MiB |

MinIO was excluded: its open-source edition stopped publishing images in October 2025,
entered maintenance mode in December 2025, and its repository was archived in April 2026.

## Options

| Option | Pros | Cons |
|---|---|---|
| Local state files | No infrastructure | Single machine; no shared locking; no versioning; migration later |
| **SeaweedFS in a container outside the clusters** | S3 API everywhere (container locally, VM on Proxmox, real S3 in cloud); locking and versioning verified; Apache-2.0 | One more always-on container |
| Garage | Very light | Unsafe locking and no versioning (spike) |
| Cloud bucket | Separate failure domain | External account; weakens "runs anywhere" |

## Decision

- **SeaweedFS** (single-container server mode, S3 API) holds all OpenTofu state except its
  own. A `bucket` with versioning enabled; `use_lockfile = true` on every backend.
- Two small **foundation** stacks create it; only they keep local (encrypted) state:
  - `foundation/store`: the SeaweedFS container and generated credentials (Docker provider).
  - `foundation/bucket`: the state bucket with versioning (AWS provider against the S3 API),
    so drift such as suspended versioning shows up in `tofu plan`.

  They are separate because a provider's configuration must be known at plan time: the
  bucket's provider needs credentials that the store only generates during apply.
  Losing either local state is recoverable (`tofu import` or re-create); the data is not
  affected. The bucket is protected with `prevent_destroy`.
- Data lives on a **host bind mount outside the repository**, not in a Docker-managed
  volume, so it survives a Docker reset and is covered by host backups.
- The S3 port binds to **127.0.0.1** only.
- All state and plan files use **OpenTofu client-side encryption** (AES-GCM).

## Consequences

- Known limits: no TLS on the loopback endpoint; the store shares the host's disk, so it
  protects against cluster loss, not host loss. Both are revisited for the Proxmox substrate.
- `lineage`, `serial` and `meta` remain readable in encrypted state files; resources and
  outputs do not.
- Lock correctness is a tested property, not an assumption: a changed store requires the
  concurrency test again.
