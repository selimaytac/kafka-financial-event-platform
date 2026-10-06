# 0038. Enforce baseline pod security and platform policies with Kyverno

- **Status:** Accepted
- **Date:** 2026-10-06

## Context

[0013](0013-use-kyverno-for-policy-as-code.md) chose Kyverno and an Audit-then-Enforce
rollout. Phase 2 installed it in Audit mode: the Pod Security Standards from the upstream
`kyverno-policies` chart, two platform policies (memory limits, no `latest` image tag) and
justified exceptions. Open questions: which controls are enforced, how the engine is kept
from blocking the platform itself, who may grant exceptions, and how a chart change is
checked before it reaches the cluster.

## Options

| Concern | Option | Trade-off |
|---|---|---|
| Policy language | `ClusterPolicy` (YAML/JMESPath) | Mature, being superseded upstream |
| | **`ValidatingPolicy` (CEL), PSS from the upstream chart** | Same language as Kubernetes admission policies; newer API |
| Scope of Enforce | Everything, restricted included | Many third-party charts fail restricted controls |
| | **Baseline PSS + memory limits + no `latest` tag; restricted stays Audit** | Restricted gaps are visible in reports but not blocked |
| Failure policy | Ignore | Enforcement silently off while Kyverno is down |
| | **Fail for enforced policies; webhooks skip `kube-system` and `kyverno`** | Kyverno outage blocks new pods elsewhere until it recovers |
| Exceptions | Annotations or labels on the workload | A namespace owner could exempt their own pods |
| | **`PolicyException` objects only in the `kyverno` namespace, each with a justification** | Every exception is a reviewed change in Git |
| Pre-merge check | Policy unit tests only | Misses Helm hook Jobs that run only on install or upgrade |
| | **Unit tests + every rendered workload of every profile against the enforced policies** | CI takes longer (charts are rendered twice) |

## Decision

- Enforced (`Deny`): the eleven baseline Pod Security Standards, `require-memory-limits`
  and `disallow-latest-tag`. The six restricted controls stay in Audit for visibility.
- `failurePolicy: Fail` for enforced policies. The platform policies derive it from their
  action; the pod-security chart has one setting, so its audit-only policies fail closed
  too. The webhooks exclude `kube-system` and `kyverno`, so the CNI and the engine can
  always start. Disabling the Kyverno addon removes its webhook configurations (verified,
  [0039](0039-keep-dev-light-with-core-and-addon-components.md)).
- Exceptions are `PolicyException` objects in the `kyverno` namespace only, named per
  workload, scoped by CEL match conditions and annotated with `kfep.io/justification`:
  - node-exporter: host namespaces, host paths, host ports (reads node metrics).
  - kind's local-path provisioner (kind only): host paths for its helper pods, and no
    memory limits (part of kind, not of this platform).
- Gateway access is not a policy: only namespaces labelled `kfep.io/gateway-access=true`
  may attach routes, a Gateway API listener rule that holds even if Kyverno is down.
- CI runs `task policies:test`: behavioural tests of the platform policies, then every
  workload of every component, profile and substrate (Helm hooks included) against the
  enforced policies.
- Rollout for a new control: Audit → read PolicyReports → fix the chart values or add an
  exception → Enforce.

## Consequences

- A component without memory limits, with a privileged pod or a `latest` image cannot be
  deployed; CI reports it before merge. Turning Enforce on required limits for cert-manager,
  the Envoy proxy (default request 512Mi, measured ~24Mi) and four hook Jobs in Argo CD,
  Envoy Gateway and kube-prometheus-stack that live reports never showed.
- While Kyverno is installed but unavailable, new pods outside `kube-system` and `kyverno`
  are rejected; existing pods keep running.
- Restricted controls (non-root, seccomp `RuntimeDefault`, no privilege escalation) are a
  known gap, reported but not enforced; the services in Phase 4 are expected to meet them.
- With the addon disabled (`dev` default) no admission policy is evaluated; `perf` and `dr`
  run the full set, and CI checks every change.
