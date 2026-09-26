# 0035. Terminate TLS at a single gateway, issued from a lab PKI outside the clusters

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

UIs and APIs need one stable, TLS-protected entry point. The lab is a guest on its host
([0034](0034-run-the-lab-as-a-guest-on-its-host.md)): no privileged ports, nothing trusted
system-wide. OIDC login (later in Phase 2) requires stable redirect URLs, which rules out
load-balancer ports that change on every rebuild. Certificates must survive cluster rebuilds
without re-trusting anything, so the trust anchor cannot live inside a disposable cluster.

## Options

| Concern | Option | Trade-off |
|---|---|---|
| Entry on kind (Docker inside a VM) | cloud-provider-kind LoadBalancer | Host port changes on every rebuild |
| | **Fixed NodePort mapped to `127.0.0.1:<profile port>`** | kind-specific setting (substrate values) |
| Hostnames | nip.io-style public DNS | Depends on an external service |
| | **`*.kfep.localhost` (RFC 6761)** | Resolves to loopback with no DNS setup |
| Trust anchor | Self-signed CA inside each cluster | New CA on every rebuild |
| | **Root CA in an OpenTofu `pki` stack; one intermediate per profile given to cert-manager** | Root key in encrypted state; not name-constrained (provider limit) |

## Decision

- `infra/stacks/pki`: ECDSA root CA (10 years) that never enters a cluster, and one
  intermediate CA per profile (1 year, planned for replacement 30 days before expiry).
  The bootstrap stack stores only the profile's intermediate (chain + key) as a secret for
  a cert-manager `ClusterIssuer`.
- The root is **not trusted** on the host: the tls provider cannot set name
  constraints. `task pki:ca-cert` exports the public certificate for `curl --cacert`.
- Envoy Gateway serves one `Gateway` with an HTTPS listener for `*.kfep.localhost`, a
  wildcard certificate (90 days, renewed 30 days early) and one `HTTPRoute` per service.
- kind maps `127.0.0.1:{dev 8443, perf 9443, dr 10443}` to NodePort 30443. On kind the
  gateway Service uses `externalTrafficPolicy: Cluster`; elsewhere `Local` keeps client IPs.

## Consequences

- Verified: `https://argocd.kfep.localhost:8443` returns 200 with the chain leaf ← dev
  intermediate ← root; without the root, clients reject the certificate; only 127.0.0.1
  listens.
- Found while testing: with `externalTrafficPolicy: Local` traffic entering the
  control-plane node was dropped because the proxy ran on the worker.
- Follow-ups: name-constrained trust anchor (OpenBao PKI); restrict `allowedRoutes` by
  namespace label with the policy baseline; authentication in front of UIs.
