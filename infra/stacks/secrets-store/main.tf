# Out-of-cluster secrets store (ADR 0040): one OpenBao for every profile on this host, so
# secrets outlive cluster rebuilds. Like the state store it is a lab guest: no auto-start,
# loopback-only on the host, data in a bind mount outside the repository (ADR 0034).
#
# No human-held keys besides secret zero (ADR 0026): the unseal key and the admin password
# are generated here and live only in this stack's encrypted state and inside the container.
# The first start initialises itself declaratively; its root token is revoked after use.
data "terraform_remote_state" "pki" {
  backend = "s3"

  config = {
    bucket                      = "opentofu-state"
    key                         = "pki/terraform.tfstate"
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
  tls            = data.terraform_remote_state.pki.outputs.openbao_tls
  hostname       = local.tls.hostname
  admin_username = "opentofu"

  # Seal key rotation: upload the new key as current, the old one as previous_key, apply.
  seal_key_id = "lab-1"

  config = <<-HCL
    ui            = false
    disable_mlock = true
    api_addr      = "https://${local.hostname}:8200"
    cluster_addr  = "https://${local.hostname}:8201"

    storage "raft" {
      path    = "/openbao/data"
      node_id = "${local.hostname}"
    }

    listener "tcp" {
      address       = "0.0.0.0:8200"
      tls_cert_file = "/openbao/tls/server-cert.pem"
      tls_key_file  = "/openbao/tls/server-key.pem"
    }

    seal "static" {
      current_key_id = "${local.seal_key_id}"
      current_key    = "file:///openbao/seal/${local.seal_key_id}.bin"
    }

    # Every request is audited to the container log. Declared here: this OpenBao version
    # rejects audit devices enabled through the API during self-initialization.
    audit "file" "stdout" {
      description = "Audit log to standard output (docker logs)."
      options {
        file_path = "stdout"
      }
    }

    # Runs once, on the first start with empty storage. Everything after it is managed by
    # OpenTofu with the admin login (the "secrets" and bootstrap stacks).
    initialize "admin" {
      request "enable-userpass" {
        operation = "update"
        path      = "sys/auth/userpass"
        data      = { type = "userpass" }
      }
      request "admin-policy" {
        operation = "update"
        path      = "sys/policies/acl/admin"
        data = {
          policy = "path \"*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\"] }"
        }
      }
      request "admin-user" {
        operation = "update"
        path      = "auth/userpass/users/${local.admin_username}"
        data = {
          password       = "${random_password.admin.result}"
          token_policies = ["admin"]
          token_ttl      = "1h"
        }
      }
    }
  HCL
}

resource "random_bytes" "seal_key" {
  length = 32 # AES-256-GCM key for the static seal
}

resource "random_password" "admin" {
  length  = 40
  special = false
}

data "docker_network" "kind" {
  name = var.network
}

resource "docker_image" "openbao" {
  name         = var.image
  keep_locally = true
}

resource "docker_container" "openbao" {
  name    = local.hostname
  image   = docker_image.openbao.image_id
  restart = "no" # started explicitly by task lab:start (ADR 0034)

  command = ["server", "-config=/openbao/config/config.hcl"]

  networks_advanced {
    name = data.docker_network.kind.name
  }

  ports {
    internal = 8200
    external = var.host_port
    ip       = "127.0.0.1"
  }

  volumes {
    host_path      = "${var.data_dir}/data"
    container_path = "/openbao/data"
  }

  upload {
    file    = "/openbao/config/config.hcl"
    content = local.config
  }
  upload {
    file    = "/openbao/tls/server-cert.pem"
    content = local.tls.cert_pem
  }
  upload {
    file    = "/openbao/tls/server-key.pem"
    content = local.tls.key_pem
  }
  upload {
    file           = "/openbao/seal/${local.seal_key_id}.bin"
    content_base64 = random_bytes.seal_key.base64
  }

  # Healthy once unsealed and serving; auto-unseal makes that the normal state after start.
  healthcheck {
    test         = ["CMD", "bao", "status", "-address=https://127.0.0.1:8200", "-tls-skip-verify"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 24
    start_period = "5s"
  }

  wait         = true
  wait_timeout = 180

  labels {
    label = "platform-labs.component"
    value = "secrets-store"
  }
}

# The root certificate is public; host-side OpenTofu providers read it from a file.
resource "local_file" "ca_cert" {
  filename        = "${var.data_dir}/ca.pem"
  content         = data.terraform_remote_state.pki.outputs.root_ca_cert_pem
  file_permission = "0644"
}
