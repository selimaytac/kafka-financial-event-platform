variable "state_passphrase" {
  description = "State encryption passphrase (secret zero). Supplied by scripts/tofu.sh."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

variable "cloud_provider_kind_image" {
  description = "cloud-provider-kind image pinned by digest."
  type        = string
  default     = "registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.11.1@sha256:40e18b9cd9c798cce40d39ff5c099a4f16a36c268d8e1dda469d73955a35e403"
}
