output "domain" {
  value = var.domain
}

output "root_ca_cert_pem" {
  description = "Public root certificate (for curl --cacert; not a secret)."
  value       = tls_self_signed_cert.root.cert_pem
}

output "intermediates" {
  description = "Per-profile intermediate CA: certificate chain and key for cert-manager."
  value = {
    for p in var.profiles : p => {
      cert_chain_pem  = "${tls_locally_signed_cert.intermediate[p].cert_pem}${tls_self_signed_cert.root.cert_pem}"
      private_key_pem = tls_private_key.intermediate[p].private_key_pem
      not_after       = tls_locally_signed_cert.intermediate[p].validity_end_time
    }
  }
  sensitive = true
}
