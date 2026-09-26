variable "image_tag" {
  description = "SeaweedFS image tag (pinned; upgrades are explicit changes)."
  type        = string
  default     = "4.47"
}

variable "container_name" {
  description = "Name of the SeaweedFS container."
  type        = string
  default     = "platform-state-store"
}

variable "data_dir" {
  description = "Absolute host path for SeaweedFS data (bind mount, outside the repository)."
  type        = string

  validation {
    condition     = startswith(var.data_dir, "/")
    error_message = "data_dir must be an absolute host path."
  }
}

variable "bind_address" {
  description = "Host address the S3 port binds to. Loopback keeps the store off the network."
  type        = string
  default     = "127.0.0.1"
}

variable "s3_port" {
  description = "Host port for the S3 API."
  type        = number
  default     = 8333
}
