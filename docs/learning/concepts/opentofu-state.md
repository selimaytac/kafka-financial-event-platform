# OpenTofu state

Applied in [ADR 0025](../../adr/0025-store-iac-state-in-out-of-cluster-seaweedfs.md) and
[ADR 0027](../../adr/0027-organise-the-repository-by-layer-and-profile.md).

## What it is

Code describes the *desired* infrastructure; it cannot know which real objects exist.
State is the record that maps every resource in the code to a real object (IDs,
attributes, dependencies, outputs). `tofu plan` compares three things: code, state and
reality, and derives create, update or delete actions from the difference.

```
code (desired) ──► plan ◄── state (last known reality) ◄──► real infrastructure
```

Without state, the tool could not tell whether a cluster was created by this code or by
someone else, and would try to create it again.

## Why it is sensitive

State is plain JSON by default and stores resource attributes, including secrets: a
cluster's admin kubeconfig with its private key, generated passwords, certificates.
Access to state is equivalent to access to what it describes.

## Four questions to ask about any state

| Question | Failure | Requirement |
|---|---|---|
| What if it is lost? | Resources become unmanaged; orphans or manual `import` | Durable storage, versioning, backups |
| What if it is stolen? | Credentials leak | Encryption at rest, access control |
| What if two runs write at once? | Corrupted state (race condition) | Locking |
| How far does one mistake reach? | One large state lets a small error touch everything | Split state by layer and environment (blast radius) |

## Mechanisms

- **Backend:** where state lives (local file, S3-compatible object store, PostgreSQL,
  Kubernetes secret, HTTP). Shared or team use calls for a remote backend.
- **Locking:** the S3 backend locks with a lock object written using a conditional
  request (`If-None-Match: *`): the write succeeds only if no lock exists. The store must
  honour the header; a store that ignores it lets two runs "hold" the lock at once without
  any error. Lock support is therefore tested, not assumed.
- **Versioning:** every write keeps the previous object version, so a corrupted or
  mistaken state can be rolled back.
- **Client-side encryption (OpenTofu):** state and plan files are encrypted before they
  leave the machine, independent of the backend. Some metadata (`lineage`, `serial`,
  `meta`) stays readable so the tool can manage the file.
- **Splitting:** each root module (stack) has exactly one state. Stack boundaries are the
  blast radius of an `apply`.

## The bootstrap problem

State for a system should live outside that system. A cluster cannot store the state that
creates it, and deleting the cluster must not delete its state. The first link in the
chain, the component that creates the state store, cannot use that store itself. The
usual answer is a small, rarely changed **foundation** stack with local (encrypted)
state, whose loss is cheap to recover from. Everything after it uses the remote backend.

The same rule applies to backups: a backup stored inside the system it protects is lost
together with that system.

## How to decide

1. List what the state will contain; if anything is a credential, encryption is mandatory.
2. Identify the failure domains: what must survive the loss of a cluster, a container
   runtime, a host?
3. Choose a backend that supports locking and versioning *verifiably* (run a concurrency
   test and a restore test).
4. Split stacks by rate of change and by blast radius, not by convenience.
