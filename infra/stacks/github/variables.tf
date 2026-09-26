variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by scripts/tofu.sh."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

variable "owner" {
  description = "GitHub account that owns the repository."
  type        = string
  default     = "selimaytac"
}

variable "repository" {
  description = "Repository name."
  type        = string
  default     = "kafka-financial-event-platform"
}
