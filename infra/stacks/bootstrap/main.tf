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

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = local.components.argocd.config.namespace
  create_namespace = true
  repository       = local.components.argocd.config.chart.repoURL
  chart            = local.components.argocd.config.chart.name
  version          = local.components.argocd.config.chart.version
  values           = local.components.argocd.values
  wait             = true
  timeout          = 600

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
            patches = [{
              target = { kind = "ApplicationSet", name = "platform" }
              patch = yamlencode([
                { op = "replace", path = "/spec/generators/0/git/revision", value = var.target_revision },
                { op = "replace", path = "/spec/template/spec/sources/1/targetRevision", value = var.target_revision },
                { op = "replace", path = "/spec/template/spec/sources/0/helm/valueFiles/1", value = "$values/{{ .path.path }}/values-${var.profile}.yaml" },
                { op = "replace", path = "/spec/template/spec/sources/0/helm/valueFiles/2", value = "$values/{{ .path.path }}/values-substrate-${local.cluster.substrate}.yaml" },
              ])
            }]
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
}
