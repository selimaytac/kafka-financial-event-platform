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

variable "profile" {
  description = "Profile name (dev, perf, dr). Supplied by scripts/tofu.sh."
  type        = string
}

variable "substrate_stack" {
  description = "Substrate stack whose outputs describe the cluster (substrate-kind, substrate-proxmox)."
  type        = string
}

variable "repo_url" {
  description = "Git repository Argo CD reconciles from."
  type        = string
  default     = "https://github.com/selimaytac/kafka-financial-event-platform.git"
}

variable "target_revision" {
  description = "Git revision Argo CD tracks. main in steady state; a branch only while developing it."
  type        = string
  default     = "main"
}
