output "kv_mounts" {
  description = "KV mount path per profile."
  value       = { for p, m in vault_mount.kv : p => m.path }
}

output "external_secrets_policies" {
  description = "Read policy name per profile."
  value       = { for p, pol in vault_policy.external_secrets : p => pol.name }
}
