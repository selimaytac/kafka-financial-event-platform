# Proxmox connection comes from the environment, never from code or state:
# PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN (a least-privilege API token).
provider "proxmox" {}

provider "talos" {}

module "cluster" {
  source            = "../../modules/proxmox-talos-cluster"
  name              = "kfep-${var.profile}"
  proxmox_node      = var.proxmox_node
  gateway           = var.gateway
  control_plane_ips = var.control_plane_ips
  worker_ips        = var.worker_ips
  kubeconfig_path   = pathexpand("~/.kube/kfep-${var.profile}.yaml")
}
