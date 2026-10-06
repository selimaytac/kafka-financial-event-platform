output "address" {
  description = "Address for host-side clients (OpenTofu, the bao CLI)."
  value       = "https://127.0.0.1:${var.host_port}"
  depends_on  = [docker_container.openbao]
}

output "internal_address" {
  description = "Address for clients on the kind network (pods, External Secrets Operator)."
  value       = "https://${local.hostname}:8200"
}

output "ca_cert_file" {
  description = "Path of the root CA that signed the server certificate (public)."
  value       = local_file.ca_cert.filename
}

output "ca_cert_pem" {
  description = "Root CA that signed the server certificate (public)."
  value       = data.terraform_remote_state.pki.outputs.root_ca_cert_pem
}

output "admin_username" {
  value = local.admin_username
}

output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}
