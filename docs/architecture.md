# Architecture

Status: design baseline (Phase 0). Sections are filled in as phases land.

## Provisioning layers

See [ADR 0003](adr/0003-layered-portable-provisioning.md).

```mermaid
flowchart TB
  subgraph L0["Layer 0 · Substrate (OpenTofu, substrate-specific)"]
    kind["kind (local)"]
    pve["Proxmox + Talos (on-prem, designed)"]
  end
  subgraph L1["Layer 1 · Bootstrap (OpenTofu)"]
    argo["Argo CD"]
  end
  subgraph L2["Layer 2 · Platform & apps (GitOps, substrate-agnostic)"]
    plat["Platform services"]
    data["Data platform"]
    apps["Applications"]
  end
  kind -- kubeconfig --> argo
  pve -- kubeconfig --> argo
  argo -- "app-of-apps + overlays<br/>(dev / perf / dr)" --> L2
```

## Data flow

Market model: [ADR 0021](adr/0021-model-a-mifid-style-regulated-equity-market.md) ·
Matching engine: [ADR 0022](adr/0022-build-a-deterministic-price-time-matching-engine.md).
Service boundaries are finalised in Phase 4.

```mermaid
flowchart LR
  sim["trader-sim<br/>synthetic participants"] --> oe["order entry<br/>pre-trade risk"]
  oe <--> valkey[("Valkey<br/>idempotency · last price")]
  oe --> orders[("orders<br/>key = instrument")]
  orders --> me["matching engine<br/>price-time · deterministic"]
  me --> exec[("executions ·<br/>book updates")]
  exec --> md["market data<br/>L1/L2 · OHLCV"]
  exec --> surv["surveillance<br/>MAR patterns"]
  exec --> pt["post-trade<br/>positions · T+2"]
  md & surv & pt --> ch[("ClickHouse<br/>analytics · audit")]
  ch --> graf["Grafana"]
  reg["Apicurio Registry"] -. schemas .- oe & me
```

## Components

Namespaces are planned and confirmed in the phase that introduces each component.

| Component | Purpose | Namespace | Config path | ADR |
|---|---|---|---|---|
| Argo CD | GitOps controller | `argocd` | _Phase 1_ | [0007](adr/0007-use-argo-cd-for-gitops.md) |
| Strimzi + Kafka | Event backbone | `kafka` | _Phase 3_ | [0008](adr/0008-run-kafka-with-strimzi-in-kraft-mode.md) |
| Apicurio Registry | Schema registry | `kafka` | _Phase 3_ | [0012](adr/0012-use-apicurio-as-schema-registry.md) |
| Kafbat UI | Kafka inspection | `kafka` | _Phase 3_ | [0016](adr/0016-use-kafbat-ui-for-kafka-inspection.md) |
| trader-sim | Synthetic market participants (load) | `apps` | _Phase 4_ | [0009](adr/0009-write-services-in-go-with-franz-go.md) |
| order entry | Validation, pre-trade risk (tick size, price corridors) | `apps` | _Phase 4_ | [0021](adr/0021-model-a-mifid-style-regulated-equity-market.md) |
| matching engine | Price-time order book, exactly-once | `apps` | _Phase 4_ | [0022](adr/0022-build-a-deterministic-price-time-matching-engine.md) |
| market data / surveillance / post-trade | Downstream consumers of executions | `apps` | _Phase 4_ | [0022](adr/0022-build-a-deterministic-price-time-matching-engine.md) |
| ClickHouse | Analytical sink and audit store | `clickhouse` | _Phase 4_ | [0010](adr/0010-use-clickhouse-as-analytical-sink.md) |
| Valkey | Dedup + cache | `apps` | _Phase 4_ | [0011](adr/0011-use-valkey-for-dedup-and-cache.md) |
| Kyverno | Admission policies | `kyverno` | _Phase 2_ | [0013](adr/0013-use-kyverno-for-policy-as-code.md) |
| Envoy Gateway | North-south traffic | `envoy-gateway-system` | _Phase 2_ | [0014](adr/0014-expose-services-with-gateway-api.md) |
| kube-prometheus-stack | Metrics, alerts, dashboards | `monitoring` | _Phase 2_ | [0015](adr/0015-use-kube-prometheus-stack-for-observability.md) |

## Profiles

| Profile | Nodes | Kafka | Lifecycle |
|---|---|---|---|
| `dev` | 1 control-plane + 1 worker | 3 combined pods, RF=3, min ISR=2 | Daily |
| `perf` | Sized for the billion-event run | Dedicated controller and broker pools | On demand |
| `dr` | Secondary site | Replica of primary | On demand, for drills |

## Delivery semantics

- Producers: `acks=all`, idempotence on.
- Order entry: idempotency keys in Valkey reject resubmitted orders.
- Matching: Kafka transactions (read-process-write), one engine loop per partition,
  deterministic replay from the order log.
- Proof: end-to-end reconciliation (produced = processed = stored), see
  [benchmarks](benchmarks/README.md).
