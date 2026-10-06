# 0039. Keep dev light: core components always, addons on demand

- **Status:** Accepted
- **Date:** 2026-10-06

## Context

Each Phase 2 component adds memory to the `dev` cluster. With monitoring and Kyverno the lab
used about 5 GB ([0037](0037-measure-and-bound-the-platform-with-kube-prometheus-stack.md)),
and the host became unresponsive several times. The cause was host memory, not CPU: CPU caps
on the node containers held, while the Docker VM on top of the host's other workloads pushed
it into heavy swapping ([0034](0034-run-the-lab-as-a-guest-on-its-host.md)). Most daily work
needs only part of the platform; Phase 3 and 4 will add Kafka and the services on top.

We need `dev` to start small, to turn a component on for the task that needs it, and to get
the memory back when it is turned off, without per-profile copies of the GitOps tree.

## Options

| Option | Pros | Cons |
|---|---|---|
| One ApplicationSet; addons disabled through values (`replicas: 0`, `enabled: false`) | No structural change | Every chart needs its own switch; CRDs, webhooks and namespaces stay |
| One ApplicationSet with a selector on a `tier` field | One object | A selector cannot combine "all core" with "these addons"; deletion behaviour is shared |
| **Two ApplicationSets from one base (core and addons), addons chosen by the bootstrap stack** | Different deletion rules per tier; the addon list is one OpenTofu variable | Core list is explicit and must be kept in sync (checked in CI) |
| Separate `dev-light` profile | Simple to explain | Another profile to keep working; still all or nothing |

## Decision

- Every `gitops/platform/<component>/config.yaml` declares `tier: core` or `tier: addon`;
  an addon may declare `requires: [...]`.
  - Core: Cilium, Argo CD, cert-manager, Envoy Gateway, the platform gateway.
  - Addons: monitoring, Kyverno, pod-security (requires Kyverno), policies (requires Kyverno).
- `gitops/root/` holds one ApplicationSet base and two Kustomize overlays:
  - `platform-core`: explicit list of core configs, `preserveResourcesOnDeletion: true`
    (removing a file must not uninstall the CNI or Argo CD).
  - `platform-addons`: files list injected by the root Application, `preserveResourcesOnDeletion: false`
    and the resources finalizer on each Application, so disabling an addon removes its
    resources. An empty selection becomes a path that matches nothing.
- The bootstrap stack's `addons` variable selects addons; plan fails if a name is not an
  addon or a `requires` is missing. Profile defaults: `dev = []`, `perf` and `dr` = all.
  `task cluster:up ADDONS=a,b` (or `none`) overrides the default.
- A core component never depends on an addon:
  - Monitors for cert-manager and Kyverno move into the monitoring addon, like those of
    Cilium and Argo CD (amends [0037](0037-measure-and-bound-the-platform-with-kube-prometheus-stack.md)).
  - The Grafana HTTPRoute moves from the gateway chart into the monitoring addon.
- Kyverno policies use `failurePolicy: Ignore` while they are in Audit, so a stopped or
  removed Kyverno cannot block pod creation. The platform policies derive it from their
  action (`Fail` only when enforced); pod-security returns to `Fail` together with Enforce
  (Kyverno rollout, ADR 0038).

## Consequences

- `dev` starts with the core only; the footprint of each addon can be measured on its own.
- Changing addons is a bootstrap apply (`cluster:up` again); Argo CD installs or removes the
  Applications. The core list is duplicated in the overlay; `task gitops:check` fails if it
  differs from the configs marked `tier: core`.
- Moving from the single `platform` ApplicationSet needs a rebuilt cluster: the old set kept
  its resources on deletion, so its addons would keep running unmanaged.
- Monitors live away from their components, and the Grafana host name is set in the
  monitoring values as well as in the gateway domain.
- With Kyverno off, admission policies are not evaluated in `dev`. CI still runs the policy
  tests, and `perf`/`dr` run the full set.
