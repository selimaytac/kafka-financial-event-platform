# Host footprint

Everything this lab places on the host ([ADR 0034](../adr/0034-run-the-lab-as-a-guest-on-its-host.md)).
`task lab:purge` removes every row marked *purged*.

| Item | Location | Purpose | Removal |
|---|---|---|---|
| Secret zero | OS keychain, service `platform-labs.kafka-financial-event-platform.tofu-state` | State encryption passphrase | purged |
| State store data | `~/platform-labs-data/kafka-financial-event-platform/seaweedfs` | OpenTofu state (bind mount) | purged |
| Provider cache | `~/platform-labs-data/kafka-financial-event-platform/plugin-cache` | OpenTofu providers | purged |
| Kubeconfigs | `~/.kube/kfep-<profile>.yaml` | Cluster admin access | purged |
| Backups | `~/platform-labs-backups/kafka-financial-event-platform/` | State archives | kept (delete by hand) |
| Foundation state | `infra/stacks/foundation/*/terraform.tfstate` (repository, gitignored) | Local encrypted state | purged |
| Stack data dirs | `infra/stacks/**/.terraform*` (repository, gitignored) | Provider links and backend config | purged |
| Docker containers | `kfep-*`, `platform-state-store`, `cloud-provider-kind`, `kindccm-*` | Clusters and services | purged |
| Docker images | `kindest/node`, `chrislusf/seaweedfs`, `cloud-provider-kind`, `envoyproxy/envoy` | Lab images | purged |
| Docker network | `kind` | kind clusters | purged only if no other kind cluster uses it |
| CLI tools | docker, kind, kubectl, helm, opentofu, task, pre-commit, gh, gitleaks, kubeconform | Tooling | not purged (may be used elsewhere) |
| Ports | 127.0.0.1:8333 (state store); lab gateway port from Phase 2 | Local endpoints | freed when containers stop |
