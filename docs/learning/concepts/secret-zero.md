# Secret zero

Applied in [ADR 0026](../../adr/0026-keep-a-single-secret-zero-in-the-os-keychain.md).

## What it is

A secret is protected by encrypting it; the encryption key is itself a secret that needs
protection, and so on. The chain must end somewhere: the one secret that is not protected
by another secret in the system is **secret zero**. Every system has one: a master
password, a KMS root key, a hardware security module, a person's login.

## Why keep it to one

Each hand-managed secret is manual work, a rotation burden and a place to leak from.
The goal is one secret zero, kept in the strongest available store, with every other
secret derived or generated from it by automation.

```
OS keychain / HSM / KMS         ← secret zero (hand-managed, strongly protected)
  └─ encryption key for state
       └─ generated credentials (object store, admin passwords, …)
            └─ consumed by automation at run time, never written in plain text
```

## Trade-offs

- **Concentration:** losing secret zero locks everything; it must be backed up
  separately (e.g. a password manager or split among custodians).
- **Scope:** one key for all environments is simpler; separate keys per environment limit
  the damage of a leak. Key rotation support makes it possible to start simple and split later.
- **Evolution:** a dedicated secrets manager (e.g. OpenBao) replaces the local store later;
  the chain stays the same, only its root moves.

## How to decide

1. List the secrets and who or what consumes them.
2. Pick the smallest possible set that must be handled by people; generate the rest.
3. Put secret zero in hardware- or OS-backed storage, with a documented backup.
4. Make rotation a routine, automated operation.
