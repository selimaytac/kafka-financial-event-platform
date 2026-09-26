variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by scripts/tofu.sh."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

variable "profile" {
  description = "Profile name (dev, perf, dr). Supplied by scripts/tofu.sh."
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox VE node that hosts the VMs."
  type        = string
}

variable "gateway" {
  description = "IPv4 gateway of the node network."
  type        = string
}

variable "control_plane_ips" {
  description = "Static IPv4 addresses of control-plane nodes (1 or 3)."
  type        = list(string)
}

variable "worker_ips" {
  description = "Static IPv4 addresses of worker nodes."
  type        = list(string)
}
