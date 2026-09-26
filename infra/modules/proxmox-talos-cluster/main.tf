# Proxmox VE + Talos Linux substrate (ADR 0005, ADR 0032).
# Designed and validated, not yet applied to a real Proxmox host.

locals {
  nodes = merge(
    { for i, ip in var.control_plane_ips : "${var.name}-cp-${i}" => { ip = ip, role = "controlplane", size = var.control_plane_size } },
    { for i, ip in var.worker_ips : "${var.name}-worker-${i}" => { ip = ip, role = "worker", size = var.worker_size } },
  )
  bootstrap_node   = var.control_plane_ips[0]
  cluster_endpoint = "https://${local.bootstrap_node}:6443"
}

# --- Talos image: built by the Image Factory with the QEMU guest agent extension.
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = ["siderolabs/qemu-guest-agent"]
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  architecture  = "amd64"
}

resource "proxmox_download_file" "talos_iso" {
  node_name    = var.proxmox_node
  datastore_id = var.iso_datastore
  content_type = "iso"
  url          = data.talos_image_factory_urls.this.urls.iso
  file_name    = "talos-${var.talos_version}-${substr(talos_image_factory_schematic.this.id, 0, 12)}-nocloud-amd64.iso"
}

# --- VMs boot the ISO into Talos maintenance mode; static IPs come from the cloud-init
# (nocloud) drive, so machine configuration can be applied to known addresses.
resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.nodes

  name      = each.key
  node_name = var.proxmox_node
  tags      = ["kfep", var.name, each.value.role]

  on_boot         = true
  stop_on_destroy = true

  cpu {
    cores = each.value.size.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.size.memory
  }

  agent {
    enabled = true
  }

  cdrom {
    file_id = proxmox_download_file.talos_iso.id
  }

  disk {
    datastore_id = var.datastore
    interface    = "scsi0"
    size         = 40
    discard      = "on"
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = var.datastore
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.prefix_length}"
        gateway = var.gateway
      }
    }
  }
}

# --- Talos: secrets, machine configuration, bootstrap, kubeconfig.
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "node" {
  for_each = local.nodes

  cluster_name       = var.name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [yamlencode({
    machine = {
      install = { disk = "/dev/sda" }
    }
    cluster = {
      # Cilium is installed by the bootstrap stack (ADR 0028), as on every substrate.
      network = { cni = { name = "none" } }
    }
  })]
}

resource "talos_machine_configuration_apply" "node" {
  for_each = local.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.node[each.key].machine_configuration
  node                        = each.value.ip

  depends_on = [proxmox_virtual_environment_vm.node]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_node

  depends_on = [talos_machine_configuration_apply.node]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_node

  depends_on = [talos_machine_bootstrap.this]
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = var.kubeconfig_path
  file_permission = "0600"
}
