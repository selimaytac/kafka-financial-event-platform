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

variable "node_image" {
  description = "kindest/node image pinned by digest (ADR 0029)."
  type        = string
}

variable "gateway_host_port" {
  description = "Host port on 127.0.0.1 for this profile's gateway."
  type        = number
}

variable "workers" {
  description = "Number of worker nodes for this profile."
  type        = number
}
