# PKI and trust anchors

Applied in [ADR 0035](../../adr/0035-terminate-tls-at-a-single-gateway-with-a-lab-pki.md).

## What a PKI is

TLS proves a server's identity with a certificate signed by an authority the client already
trusts. A public key infrastructure (PKI) is the chain behind that signature:

```
root CA (trust anchor, rarely used, long-lived)
  └─ intermediate CA (signs day to day, shorter-lived, replaceable)
       └─ leaf certificate (the server, short-lived, renewed automatically)
```

Clients store only the root. Everything below it is presented by the server and verified
link by link.

## Why the hierarchy

- **Blast radius:** if an intermediate key leaks, it is revoked and replaced; the root, and
  every client's trust configuration, stay unchanged.
- **Key exposure:** the root key is used only to sign intermediates, so it can stay offline;
  the online systems hold only intermediate keys.
- **Lifetimes:** short-lived leaves make revocation less critical; renewal must therefore be
  automatic, otherwise expiry becomes an outage.

## Trust anchors must outlive what they certify

A disposable cluster that creates its own CA forces clients to trust a new anchor after
every rebuild. The anchor belongs outside the disposable part, like state and backups.

## Trusting an anchor is a security decision for the whole machine

Adding a root to a system trust store lets whoever holds its key impersonate any website to
that machine. Mitigations:

- **Name constraints** (X.509): the CA may only issue for listed domains; modern clients
  enforce them.
- **Scope:** trust in a separate browser profile or per tool (`curl --cacert`) instead of the
  system store.
- **Opt-in and reversible:** never as a silent side effect of setup.

## How to decide

1. Decide where the root key lives and who can use it; keep it out of systems that are rebuilt.
2. Give each environment its own intermediate with a short lifetime.
3. Automate renewal at every level and make expiry visible (plans, alerts).
4. Treat client trust as a separate, explicit decision.
