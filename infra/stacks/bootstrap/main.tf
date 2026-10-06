# Layer 1 (ADR 0003): install the CNI and Argo CD, then hand over to GitOps.
# Only the substrate's output contract is used here, never the substrate itself.
data "terraform_remote_state" "substrate" {
  backend = "s3"

  config = {
    bucket                      = "opentofu-state"
    key                         = "${var.substrate_stack}/${var.profile}/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = var.state_endpoint }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

# Lab PKI (ADR 0035): only this profile's intermediate CA enters the cluster.
data "terraform_remote_state" "pki" {
  backend = "s3"

  config = {
    bucket                      = "opentofu-state"
    key                         = "pki/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = var.state_endpoint }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

locals {
  cluster  = data.terraform_remote_state.substrate.outputs
  platform = "${path.root}/../../../gitops/platform"

  # Chart versions and values come from the GitOps tree, the same files Argo CD renders,
  # so the bootstrap and the adopted releases cannot diverge.
  components = {
    for name in ["cilium", "argocd"] : name => {
      config = yamldecode(file("${local.platform}/${name}/config.yaml"))
      values = compact([
        file("${local.platform}/${name}/values.yaml"),
        fileexists("${local.platform}/${name}/values-${var.profile}.yaml") ? file("${local.platform}/${name}/values-${var.profile}.yaml") : "",
        fileexists("${local.platform}/${name}/values-substrate-${local.cluster.substrate}.yaml") ? file("${local.platform}/${name}/values-substrate-${local.cluster.substrate}.yaml") : "",
      ])
    }
  }

  # Addons selected for this cluster (ADR 0039). A missing config reads as an empty tier so
  # that the precondition on the root release reports it instead of file() failing.
  addons = {
    for name in var.addons : name => {
      tier     = try(yamldecode(file("${local.platform}/${name}/config.yaml")).tier, "")
      requires = try(tolist(yamldecode(file("${local.platform}/${name}/config.yaml")).requires), tolist([]))
    }
  }
  # An empty list would make the generator read every file; a path that matches nothing
  # keeps the addons ApplicationSet empty.
  addon_files = length(var.addons) > 0 ? [
    for name in var.addons : { path = "gitops/platform/${name}/config.yaml" }
  ] : [{ path = "gitops/platform/none/config.yaml" }]
}

provider "kubernetes" {
  host                   = local.cluster.endpoint
  cluster_ca_certificate = local.cluster.cluster_ca_certificate
  client_certificate     = local.cluster.client_certificate
  client_key             = local.cluster.client_key
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster.endpoint
    cluster_ca_certificate = local.cluster.cluster_ca_certificate
    client_certificate     = local.cluster.client_certificate
    client_key             = local.cluster.client_key
  }
}

# Bootstrap-and-adopt (ADR 0028, ADR 0030): installed once here, owned by Argo CD afterwards.
# ignore_changes = all keeps OpenTofu from fighting Argo CD over later upgrades.
resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = local.components.cilium.config.namespace
  repository = local.components.cilium.config.chart.repoURL
  chart      = local.components.cilium.config.chart.name
  version    = local.components.cilium.config.chart.version
  values     = local.components.cilium.values
  wait       = true
  timeout    = 600

  lifecycle {
    ignore_changes = all
  }
}

# Owned here, like the other namespaces, so that a rebuilt cluster gets it with its labels.
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = local.components.argocd.config.namespace
    labels = {
      "kfep.io/gateway-access" = "true" # Argo CD is published through the gateway (ADR 0038)
    }
  }

  depends_on = [helm_release.cilium]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = local.components.argocd.config.chart.repoURL
  chart      = local.components.argocd.config.chart.name
  version    = local.components.argocd.config.chart.version
  values     = local.components.argocd.values
  wait       = true
  timeout    = 600

  depends_on = [helm_release.cilium]

  lifecycle {
    ignore_changes = all
  }
}

# The root Application is the one object OpenTofu keeps owning: it anchors the cluster to
# Git and carries the profile and revision into the GitOps tree.
resource "helm_release" "root" {
  name       = "root"
  namespace  = helm_release.argocd.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"

  values = [yamlencode({
    applications = {
      root = {
        namespace = helm_release.argocd.namespace
        project   = "default"
        source = {
          repoURL        = var.repo_url
          targetRevision = var.target_revision
          path           = "gitops/root"
          kustomize = {
            patches = [
              {
                # Both ApplicationSets (core and addons) receive the same cluster parameters.
                target = { kind = "ApplicationSet", name = "platform-.*" }
                patch = yamlencode([
                  { op = "replace", path = "/spec/generators/0/matrix/generators/0/git/revision", value = var.target_revision },
                  {
                    op    = "replace"
                    path  = "/spec/generators/0/matrix/generators/1/list/elements/0"
                    value = { profile = var.profile, substrate = local.cluster.substrate, revision = var.target_revision }
                  },
                ])
              },
              {
                target = { kind = "ApplicationSet", name = "platform-addons" }
                patch = yamlencode([
                  { op = "replace", path = "/spec/generators/0/matrix/generators/0/git/files", value = local.addon_files },
                ])
              },
            ]
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = helm_release.argocd.namespace
        }
        syncPolicy = {
          automated = { prune = true, selfHeal = true }
        }
      }
    }
  })]

  lifecycle {
    precondition {
      condition     = alltrue([for name, config in local.addons : config.tier == "addon"])
      error_message = "Every entry in addons must be a component with tier: addon in gitops/platform/<name>/config.yaml."
    }
    precondition {
      condition = alltrue([
        for name, config in local.addons : alltrue([for required in config.requires : contains(var.addons, required)])
      ])
      error_message = "An addon is missing one of its requires; add it to addons as well."
    }
  }
}

# The issuing CA for cert-manager. The namespace is created here because the secret must
# exist before cert-manager's ClusterIssuer can become ready; Argo CD's CreateNamespace
# then finds it in place.
resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_secret_v1" "intermediate_ca" {
  metadata {
    name      = "kfep-intermediate-ca"
    namespace = kubernetes_namespace_v1.cert_manager.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = data.terraform_remote_state.pki.outputs.intermediates[var.profile].cert_chain_pem
    "tls.key" = data.terraform_remote_state.pki.outputs.intermediates[var.profile].private_key_pem
    "ca.crt"  = data.terraform_remote_state.pki.outputs.root_ca_cert_pem
  }
}

# Grafana admin credentials (ADR 0026, ADR 0037): generated here so they are stable across
# renders; a chart-generated password would change on every sync. Moves to the secrets
# manager later in Phase 2.
resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "kfep.io/gateway-access" = "true" # Grafana is published through the gateway
    }
  }
}

# A label-only resource did not survive a rebuild: its refresh ran before the release had
# created the namespace, so nothing was planned and the label was missing.
removed {
  from = kubernetes_labels.argocd_gateway_access

  lifecycle {
    destroy = false
  }
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "admin-user"     = "admin"
    "admin-password" = random_password.grafana_admin.result
  }
}
