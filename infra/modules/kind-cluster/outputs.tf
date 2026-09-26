output "name" {
  description = "Cluster name."
  value       = kind_cluster.this.name
}

output "endpoint" {
  description = "Kubernetes API endpoint reachable from the host."
  value       = kind_cluster.this.endpoint
}

output "kubeconfig_path" {
  description = "Path of the written kubeconfig file."
  value       = kind_cluster.this.kubeconfig_path
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (PEM)."
  value       = kind_cluster.this.cluster_ca_certificate
}

output "client_certificate" {
  description = "Admin client certificate (PEM)."
  value       = kind_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Admin client key (PEM)."
  value       = kind_cluster.this.client_key
  sensitive   = true
}
