# Contract shared by every substrate stack (kind, Proxmox/Talos): the bootstrap layer
# only depends on these outputs, never on the substrate itself (ADR 0003).
output "substrate" {
  description = "Substrate type; selects values-substrate-<type>.yaml in the GitOps tree."
  value       = "kind"
}

output "cluster_name" {
  value = module.cluster.name
}

output "endpoint" {
  value = module.cluster.endpoint
}

output "kubeconfig_path" {
  value = module.cluster.kubeconfig_path
}

output "cluster_ca_certificate" {
  value = module.cluster.cluster_ca_certificate
}

output "client_certificate" {
  value     = module.cluster.client_certificate
  sensitive = true
}

output "client_key" {
  value     = module.cluster.client_key
  sensitive = true
}
