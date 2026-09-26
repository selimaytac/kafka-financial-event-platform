module "state_store" {
  source   = "../../../modules/seaweedfs-local"
  data_dir = var.state_store_data_dir
}

provider "docker" {}
