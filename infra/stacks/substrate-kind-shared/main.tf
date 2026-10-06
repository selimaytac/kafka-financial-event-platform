provider "docker" {}

# One instance serves every kind cluster on this Docker host, so it lives in a
# profile-less stack instead of being created per cluster.
resource "docker_image" "cloud_provider_kind" {
  name         = var.cloud_provider_kind_image
  keep_locally = true
}

resource "docker_container" "cloud_provider_kind" {
  name  = "cloud-provider-kind"
  image = docker_image.cloud_provider_kind.image_id
  # Lab containers never start by themselves when Docker starts (the lab is a guest,
  # ADR 0034); `task lab:start` starts them explicitly.
  restart = "no"

  # Watches the Docker API for kind clusters and creates load-balancer containers.
  # Mounting the Docker socket is root-equivalent on the Docker host; accepted locally.
  network_mode = "host"
  command      = ["--enable-lb-port-mapping"]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  labels {
    label = "platform-labs.component"
    value = "load-balancer-controller"
  }
}
