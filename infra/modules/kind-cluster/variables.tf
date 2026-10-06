variable "name" {
  description = "Cluster name."
  type        = string
}

variable "node_image" {
  description = "kindest/node image pinned by digest matching the embedded kind release (ADR 0029)."
  type        = string

  validation {
    condition     = can(regex("^kindest/node:v[0-9.]+@sha256:[0-9a-f]{64}$", var.node_image))
    error_message = "node_image must be pinned by digest: kindest/node:vX.Y.Z@sha256:<digest>."
  }
}

variable "workers" {
  description = "Number of worker nodes."
  type        = number

  validation {
    condition     = var.workers >= 1 && var.workers <= 6
    error_message = "workers must be between 1 and 6."
  }
}

variable "gateway_host_port" {
  description = "Host port on 127.0.0.1 that reaches the gateway NodePort (ADR 0034: loopback, high port)."
  type        = number
}

variable "gateway_node_port" {
  description = "Fixed NodePort of the gateway Service on kind (values-substrate-kind.yaml)."
  type        = number
  default     = 30443
}

variable "cpu_caps" {
  description = "CPU cap per node container (Docker --cpus); 0 disables the cap. Protects the host (ADR 0034)."
  type        = object({ control_plane = number, worker = number })
  default     = { control_plane = 0, worker = 0 }
}

variable "kubeconfig_path" {
  description = "Where to write this cluster's kubeconfig (a dedicated file, never the default one)."
  type        = string
}
