provider "kind" {}

module "cluster" {
  source            = "../../modules/kind-cluster"
  name              = "kfep-${var.profile}"
  node_image        = var.node_image
  workers           = var.workers
  gateway_host_port = var.gateway_host_port
  cpu_caps          = var.cpu_caps
  kubeconfig_path   = pathexpand("~/.kube/kfep-${var.profile}.yaml")
}
