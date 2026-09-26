variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by the task wrapper."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

variable "state_store_data_dir" {
  description = "Absolute host path for state store data, outside the repository."
  type        = string
}
