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
