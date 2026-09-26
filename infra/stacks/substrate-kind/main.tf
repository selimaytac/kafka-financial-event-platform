provider "kind" {}

module "cluster" {
  source          = "../../modules/kind-cluster"
  name            = "kfep-${var.profile}"
  node_image      = var.node_image
  workers         = var.workers
  kubeconfig_path = pathexpand("~/.kube/kfep-${var.profile}.yaml")
}
