variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by the task wrapper."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

# Read from the store stack's outputs by the task wrapper. They live in a separate
# stack because provider configuration must be known at plan time.
variable "s3_endpoint" {
  description = "S3 endpoint of the state store."
  type        = string
}

variable "s3_access_key" {
  description = "S3 access key."
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "S3 secret key."
  type        = string
  sensitive   = true
}

variable "state_bucket" {
  description = "Bucket that holds the OpenTofu state of all other stacks."
  type        = string
  default     = "opentofu-state"
}
