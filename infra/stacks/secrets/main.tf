# Secret data and access policies in the out-of-cluster OpenBao (ADR 0040). This stack is
# independent of any cluster: destroying and recreating a cluster keeps every value here.
# The per-cluster trust (Kubernetes auth) lives in the bootstrap stack.
data "terraform_remote_state" "secrets_store" {
  backend = "s3"

  config = {
    bucket                      = "opentofu-state"
    key                         = "secrets-store/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = var.state_endpoint }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

locals {
  store = data.terraform_remote_state.secrets_store.outputs
}

provider "vault" {
  address          = local.store.address
  ca_cert_file     = local.store.ca_cert_file
  skip_child_token = true

  auth_login_userpass {
    username = local.store.admin_username
    password = local.store.admin_password
  }
}

# One KV v2 mount per profile: a cluster can only ever read its own profile's secrets.
resource "vault_mount" "kv" {
  for_each = var.profiles

  path        = "kfep-${each.key}"
  type        = "kv"
  options     = { version = "2" }
  description = "Secrets for the ${each.key} cluster (ADR 0040)"
}

# Read-only access for External Secrets Operator; bound to a service account per cluster
# by the bootstrap stack.
resource "vault_policy" "external_secrets" {
  for_each = var.profiles

  name   = "external-secrets-${each.key}"
  policy = <<-HCL
    path "${vault_mount.kv[each.key].path}/data/*" {
      capabilities = ["read"]
    }
    path "${vault_mount.kv[each.key].path}/metadata/*" {
      capabilities = ["read", "list"]
    }
  HCL
}

# Grafana admin login (ADR 0037), generated once per profile.
resource "random_password" "grafana_admin" {
  for_each = var.profiles

  length  = 32
  special = false
}

resource "vault_kv_secret_v2" "grafana_admin" {
  for_each = var.profiles

  mount = vault_mount.kv[each.key].path
  name  = "grafana-admin"
  data_json = jsonencode({
    "admin-user"     = "admin"
    "admin-password" = random_password.grafana_admin[each.key].result
  })
}
