output "endpoint" {
  description = "S3 endpoint of the state store."
  value       = module.state_store.endpoint
}

output "access_key" {
  description = "S3 access key."
  value       = module.state_store.access_key
  sensitive   = true
}

output "secret_key" {
  description = "S3 secret key."
  value       = module.state_store.secret_key
  sensitive   = true
}
