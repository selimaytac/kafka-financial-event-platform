output "argocd_namespace" {
  value = helm_release.argocd.namespace
}

output "tracked_revision" {
  value = var.target_revision
}
