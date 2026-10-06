variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by scripts/tofu.sh."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

variable "state_endpoint" {
  description = "S3 endpoint of the state store. Supplied by scripts/tofu.sh."
  type        = string
}

variable "data_dir" {
  description = "Absolute host directory for OpenBao (data and public CA), outside the repository. Supplied by scripts/tofu.sh."
  type        = string

  validation {
    condition     = startswith(var.data_dir, "/")
    error_message = "data_dir must be an absolute host path."
  }
}

variable "image" {
  description = "OpenBao image, pinned by digest (upgrades are explicit changes)."
  type        = string
  default     = "ghcr.io/openbao/openbao:2.7.1@sha256:6d2b93856e3fcf7b18ad855a0b51eaba474dc8b79cf554379ea32034797d2acf"
}

variable "network" {
  description = "Docker network shared with the kind nodes, so pods and API servers reach OpenBao by name."
  type        = string
  default     = "kind"
}

variable "host_port" {
  description = "Loopback port for host-side clients (OpenTofu, the bao CLI)."
  type        = number
  default     = 8200
}
