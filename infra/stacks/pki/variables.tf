variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by scripts/tofu.sh."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

variable "domain" {
  description = "Lab DNS domain; all issued names live under it (RFC 6761 .localhost)."
  type        = string
  default     = "kfep.localhost"
}

variable "profiles" {
  description = "Profiles that get an intermediate CA."
  type        = set(string)
  default     = ["dev", "perf", "dr"]
}
