# 0013. Use Kyverno for policy as code

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

Governance controls (no privileged pods, resource limits, required labels, image
provenance, retention settings on topics) must be enforced automatically and testable
before they reach the cluster.

## Options

| Option | License | Pros | Cons |
|---|---|---|---|
| Kyverno | Apache-2.0, CNCF | Policies are Kubernetes YAML, validate/mutate/generate, CLI for offline tests | YAML can get verbose for complex logic |
| OPA Gatekeeper | Apache-2.0, CNCF | Rego is very expressive, general-purpose | Extra language to learn and maintain |
| Pod Security Admission only | Built-in | Zero install | Only pod security; no custom rules |

## Decision

Use **Kyverno** for admission policies, tested offline with the Kyverno CLI in CI.

## Consequences

- Policies map to rows in the compliance control matrix.
- Rollout pattern: `Audit` first, then `Enforce`, documented per policy.
