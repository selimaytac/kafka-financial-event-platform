# Lab PKI (ADR 0035). The root CA never enters a cluster; each profile gets a short-lived
# intermediate CA that cert-manager uses to issue certificates.
#
# Known limit: the tls provider cannot set X.509 name constraints, so this root is NOT
# trusted on the host. Opt-in trust waits for a name-constrained root (ADR 0034).

resource "tls_private_key" "root" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "root" {
  private_key_pem   = tls_private_key.root.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = "kfep lab root CA"
    organization = "kafka-financial-event-platform (lab)"
  }

  validity_period_hours = 87600 # 10 years: the trust anchor outlives clusters
  allowed_uses          = ["cert_signing", "crl_signing", "digital_signature"]
}

resource "tls_private_key" "intermediate" {
  for_each = var.profiles

  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "intermediate" {
  for_each = var.profiles

  private_key_pem = tls_private_key.intermediate[each.key].private_key_pem

  subject {
    common_name  = "kfep ${each.key} intermediate CA"
    organization = "kafka-financial-event-platform (lab)"
  }
}

resource "tls_locally_signed_cert" "intermediate" {
  for_each = var.profiles

  cert_request_pem   = tls_cert_request.intermediate[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem
  is_ca_certificate  = true

  validity_period_hours = 8760 # 1 year
  # Inside the last 30 days, plan shows a replacement: expiry becomes a visible change,
  # not a silent outage.
  early_renewal_hours = 720
  allowed_uses        = ["cert_signing", "crl_signing", "digital_signature"]
}
