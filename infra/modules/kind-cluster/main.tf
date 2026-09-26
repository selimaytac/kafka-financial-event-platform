resource "kind_cluster" "this" {
  name            = var.name
  node_image      = var.node_image
  kubeconfig_path = var.kubeconfig_path

  # Nodes stay NotReady until a CNI is installed (ADR 0028), so do not wait for readiness here.
  wait_for_ready = false

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      disable_default_cni = true
    }

    node {
      role = "control-plane"

      # Stable entry point: 127.0.0.1:<profile port> -> gateway NodePort. A random
      # load-balancer port would break OIDC redirect URLs (ADR 0035).
      extra_port_mappings {
        container_port = var.gateway_node_port
        host_port      = var.gateway_host_port
        listen_address = "127.0.0.1"
        protocol       = "TCP"
      }
    }

    dynamic "node" {
      for_each = range(var.workers)
      content {
        role = "worker"
      }
    }
  }
}

# Pod limits protect the node, not the host: without a cap, node containers can use every
# CPU the Docker VM is given, and a start-up burst can saturate the whole host (observed).
# CPU is compressible (throttled, never killed), so capping it is safe. Memory is not capped
# here: the kubelet would not see a container memory limit and would over-commit the node.
locals {
  worker_names = [for i in range(var.workers) : i == 0 ? "${var.name}-worker" : "${var.name}-worker${i + 1}"]
  cpu_caps = merge(
    var.cpu_caps.control_plane > 0 ? { "${var.name}-control-plane" = var.cpu_caps.control_plane } : {},
    var.cpu_caps.worker > 0 ? { for n in local.worker_names : n => var.cpu_caps.worker } : {},
  )
}

resource "terraform_data" "cpu_cap" {
  for_each = local.cpu_caps

  # Re-applied when the cluster is re-created or the cap changes; docker update persists
  # across container restarts.
  triggers_replace = [kind_cluster.this.id, each.value]

  provisioner "local-exec" {
    command = "docker update --cpus ${each.value} ${each.key}"
  }
}
