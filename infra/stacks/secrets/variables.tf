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

variable "profiles" {
  description = "Profiles that get their own secrets path."
  type        = set(string)
  default     = ["dev", "perf", "dr"]
}
