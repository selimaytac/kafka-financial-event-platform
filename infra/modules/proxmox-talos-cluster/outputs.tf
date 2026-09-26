# Same contract as the kind module. The client configuration returned by Talos is
# base64-encoded (kubeconfig "-data" fields); decoded here to PEM.
# To be confirmed on the first real apply (ADR 0032).
output "name" {
  value = var.name
}

output "endpoint" {
  value = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
}

output "kubeconfig_path" {
  value = local_sensitive_file.kubeconfig.filename
}

output "cluster_ca_certificate" {
  value = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
}

output "client_certificate" {
  value     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  sensitive = true
}

output "client_key" {
  value     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  sensitive = true
}
