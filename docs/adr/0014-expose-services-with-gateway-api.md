# 0014. Expose services with Gateway API (Envoy Gateway) and cloud-provider-kind

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

UIs and APIs (Grafana, Argo CD, Kafbat UI, service APIs) need load-balanced, TLS-terminated
entry points. The Kubernetes project retired Ingress-NGINX in 2026; Gateway API is
the successor standard. kind has no cloud load balancer by default.

## Options

| Option | Pros | Cons |
|---|---|---|
| Gateway API + Envoy Gateway | Standard API, role-oriented, rich traffic policies (rate limit, authn), CNCF Envoy | Newer than Ingress |
| Ingress-NGINX | Well known | Retired upstream (no more fixes); less expressive |
| Port-forward / NodePort | Nothing to install | Not how production traffic flows |

## Decision

Use **Gateway API** with **Envoy Gateway**, and **cloud-provider-kind** to provide
`LoadBalancer` services locally. On Proxmox, a bare-metal LB (e.g. MetalLB or Cilium LB-IPAM)
fills the same role.

## Consequences

- The same `Gateway`/`HTTPRoute` manifests work on every substrate.
- TLS certificates come from cert-manager (Phase 2).
