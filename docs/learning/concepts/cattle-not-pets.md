# Cattle, not pets: disposable environments

Applied in [ADR 0003](../../adr/0003-layered-portable-provisioning.md) and the
[cluster lifecycle runbook](../../runbooks/cluster-lifecycle.md).

## The idea

A *pet* server is built and repaired by hand; losing it is a crisis because nobody can
recreate it exactly. *Cattle* are identical and replaceable: when one fails, a new one is
created from the same definition. The difference is not the hardware, but whether the
complete definition lives in code.

## What it takes

- Every layer is declared: substrate, bootstrap, platform, applications.
- State that must survive (IaC state, business data, backups) lives **outside** the
  disposable part.
- Creation and destruction are routine, tested operations, in a known order (destroy in
  the reverse order of creation).
- Rebuild time is measured; it becomes an input to recovery objectives (RTO).

## Why it matters for operations

- Recovery from an unknown broken state is often faster by rebuilding than by debugging.
- Upgrades can be done by building a new environment and moving traffic (blue/green),
  not only by changing a running one.
- Drift cannot accumulate unnoticed if environments are rebuilt regularly.

## Limits

Data is not cattle. A disposable cluster still needs its data restored from a backup or
replicated from elsewhere; the rebuild time without data is only the lower bound of
recovery time.
