# Architecture Decision Records

Process: [0001](0001-record-architecture-decisions.md) · Template: [template.md](template.md)

| # | Decision | Status |
|---|---|---|
| 0001 | [Record architecture decisions](0001-record-architecture-decisions.md) | Accepted |
| 0002 | [Define "one billion events" as cumulative throughput](0002-define-billion-as-cumulative-throughput.md) | Accepted |
| 0003 | [Layered, portable provisioning with environment profiles](0003-layered-portable-provisioning.md) | Accepted |
| 0004 | [Use kind as the local substrate with a two-node dev profile](0004-use-kind-for-local-substrate.md) | Accepted |
| 0005 | [Design Proxmox + Talos Linux as the second substrate](0005-design-proxmox-talos-as-second-substrate.md) | Accepted |
| 0006 | [Use OpenTofu for infrastructure as code](0006-use-opentofu-for-infrastructure-as-code.md) | Accepted |
| 0007 | [Use Argo CD (app-of-apps) for GitOps](0007-use-argo-cd-for-gitops.md) | Superseded by [0030](0030-generate-applications-with-applicationsets.md) (pattern only; Argo CD remains the GitOps controller) |
| 0008 | [Run Kafka with Strimzi in KRaft mode](0008-run-kafka-with-strimzi-in-kraft-mode.md) | Accepted |
| 0009 | [Write services in Go with franz-go](0009-write-services-in-go-with-franz-go.md) | Accepted |
| 0010 | [Use ClickHouse (Altinity operator) as the analytical sink](0010-use-clickhouse-as-analytical-sink.md) | Accepted |
| 0011 | [Use Valkey for deduplication and last-price cache](0011-use-valkey-for-dedup-and-cache.md) | Accepted |
| 0012 | [Use Apicurio Registry for event schemas](0012-use-apicurio-as-schema-registry.md) | Accepted |
| 0013 | [Use Kyverno for policy as code](0013-use-kyverno-for-policy-as-code.md) | Accepted |
| 0014 | [Expose services with Gateway API (Envoy Gateway) and cloud-provider-kind](0014-expose-services-with-gateway-api.md) | Accepted |
| 0015 | [Use kube-prometheus-stack for metrics and dashboards](0015-use-kube-prometheus-stack-for-observability.md) | Accepted |
| 0016 | [Use Kafbat UI for Kafka inspection](0016-use-kafbat-ui-for-kafka-inspection.md) | Accepted |
| 0017 | [Test at four layers: application, infrastructure, load, chaos](0017-test-at-four-layers.md) | Accepted |
| 0018 | [Use GitHub Actions for CI](0018-use-github-actions-for-ci.md) | Accepted |
| 0019 | [Treat financial regulations as reference frameworks for controls](0019-treat-regulations-as-reference-frameworks.md) | Accepted |
| 0020 | [Enforce repository hygiene with pre-commit, gitleaks and Conventional Commits](0020-enforce-repository-hygiene-with-pre-commit.md) | Accepted |
| 0021 | [Model a MiFID II-style regulated equity market](0021-model-a-mifid-style-regulated-equity-market.md) | Accepted |
| 0022 | [Build a deterministic price-time priority matching engine on Kafka](0022-build-a-deterministic-price-time-matching-engine.md) | Accepted |
| 0023 | [Present the repository as a learning project and separate learning notes from operational docs](0023-separate-learning-notes-from-operational-docs.md) | Accepted |
| 0024 | [Protect `main` with a ruleset and pin all third-party code by commit SHA](0024-protect-main-and-pin-third-party-code.md) | Accepted |
| 0025 | [Store IaC state in out-of-cluster SeaweedFS with locking, versioning and encryption](0025-store-iac-state-in-out-of-cluster-seaweedfs.md) | Accepted |
| 0026 | [Keep a single secret zero in the OS keychain; generate all other secrets](0026-keep-a-single-secret-zero-in-the-os-keychain.md) | Accepted |
| 0027 | [Organise the repository by layer and select profiles explicitly](0027-organise-the-repository-by-layer-and-profile.md) | Accepted |
| 0028 | [Use Cilium as the CNI on every substrate, installed with bootstrap-and-adopt](0028-use-cilium-as-cni-with-bootstrap-and-adopt.md) | Accepted |
| 0029 | [Pin Kubernetes through the kind provider, by image digest](0029-pin-kubernetes-through-the-kind-provider.md) | Accepted |
| 0030 | [Generate Argo CD Applications with ApplicationSets; OpenTofu owns only the root](0030-generate-applications-with-applicationsets.md) | Accepted |
| 0031 | [Manage repository settings and branch protection as code](0031-manage-repository-settings-as-code.md) | Accepted |
| 0032 | [Implement the Proxmox + Talos substrate behind the same output contract](0032-implement-the-proxmox-talos-substrate-behind-the-same-contract.md) | Accepted |
| 0033 | [Guard reconciliation-critical components: manual sync and pre-merge rendering](0033-guard-reconciliation-critical-components.md) | Accepted |
| 0034 | [Run the lab as a guest on its host: minimal footprint, explicit start, graded recovery](0034-run-the-lab-as-a-guest-on-its-host.md) | Accepted |
| 0035 | [Terminate TLS at a single gateway, issued from a lab PKI outside the clusters](0035-terminate-tls-at-a-single-gateway-with-a-lab-pki.md) | Accepted |
| 0036 | [Inject cluster parameters once, support all chart sources, and diff server-side](0036-inject-cluster-parameters-once-and-diff-server-side.md) | Accepted |
| 0037 | [Measure and bound the platform: metrics, alerts and explicit resource limits](0037-measure-and-bound-the-platform-with-kube-prometheus-stack.md) | Accepted |
