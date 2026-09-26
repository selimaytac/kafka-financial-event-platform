variable "name" {
  description = "Cluster name."
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox VE node that hosts the VMs."
  type        = string
}

variable "datastore" {
  description = "Datastore for VM disks."
  type        = string
  default     = "local-lvm"
}

variable "iso_datastore" {
  description = "Datastore that accepts ISO images."
  type        = string
  default     = "local"
}

variable "bridge" {
  description = "Network bridge for the VMs."
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "IPv4 gateway of the node network."
  type        = string
}

variable "prefix_length" {
  description = "IPv4 prefix length of the node network."
  type        = number
  default     = 24
}

variable "control_plane_ips" {
  description = "Static IPv4 addresses of control-plane nodes (1 or 3)."
  type        = list(string)

  validation {
    condition     = contains([1, 3], length(var.control_plane_ips))
    error_message = "Use 1 or 3 control-plane nodes (etcd quorum)."
  }
}

variable "worker_ips" {
  description = "Static IPv4 addresses of worker nodes."
  type        = list(string)
}

variable "talos_version" {
  description = "Talos Linux version (image and machine configuration)."
  type        = string
  default     = "v1.14.1"
}

variable "kubernetes_version" {
  description = "Kubernetes version installed by Talos."
  type        = string
  default     = "1.35.0"
}

variable "control_plane_size" {
  description = "vCPU and memory (MiB) per control-plane VM."
  type        = object({ cores = number, memory = number })
  default     = { cores = 2, memory = 4096 }
}

variable "worker_size" {
  description = "vCPU and memory (MiB) per worker VM."
  type        = object({ cores = number, memory = number })
  default     = { cores = 4, memory = 8192 }
}

variable "kubeconfig_path" {
  description = "Where to write this cluster's kubeconfig (a dedicated file)."
  type        = string
}
