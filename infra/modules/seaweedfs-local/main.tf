# Credentials are generated here and only ever uploaded into the container;
# they are never written to the host filesystem in plain text.
resource "random_password" "access_key" {
  length  = 20
  special = false
}

resource "random_password" "secret_key" {
  length  = 40
  special = false
}

locals {
  s3_config = jsonencode({
    identities = [{
      name = "opentofu"
      credentials = [{
        accessKey = random_password.access_key.result
        secretKey = random_password.secret_key.result
      }]
      actions = ["Admin", "Read", "Write", "List", "Tagging"]
    }]
  })
}

resource "docker_image" "seaweedfs" {
  name         = "chrislusf/seaweedfs:${var.image_tag}"
  keep_locally = true
}

resource "docker_container" "seaweedfs" {
  name  = var.container_name
  image = docker_image.seaweedfs.image_id
  # Lab containers never start by themselves when Docker starts (the lab is a guest,
  # ADR 0034); `task lab:start` starts them explicitly.
  restart = "no"

  command = [
    "server",
    "-dir=/data",
    "-s3",
    "-s3.port=8333",
    "-s3.config=/etc/seaweedfs/s3.json",
  ]

  ports {
    internal = 8333
    external = var.s3_port
    ip       = var.bind_address
  }

  volumes {
    host_path      = var.data_dir
    container_path = "/data"
  }

  upload {
    file    = "/etc/seaweedfs/s3.json"
    content = local.s3_config
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8333/healthz"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 12
    start_period = "5s"
  }

  # Block until the healthcheck passes so dependent resources can use the API.
  wait         = true
  wait_timeout = 120

  labels {
    label = "platform-labs.component"
    value = "state-store"
  }
}
