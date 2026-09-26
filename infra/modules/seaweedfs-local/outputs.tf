output "endpoint" {
  description = "S3 API endpoint."
  value       = "http://${var.bind_address}:${var.s3_port}"
  depends_on  = [docker_container.seaweedfs]
}

output "access_key" {
  description = "S3 access key."
  value       = random_password.access_key.result
  sensitive   = true
}

output "secret_key" {
  description = "S3 secret key."
  value       = random_password.secret_key.result
  sensitive   = true
}
