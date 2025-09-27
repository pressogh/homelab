locals {
  longhorn_namespace_manifest = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "longhorn-system"
      labels = {
        "pod-security.kubernetes.io/enforce" = "privileged"
      }
    }
  })

  longhorn_manifest = join("---\n", [
    local.longhorn_namespace_manifest,
    data.helm_template.longhorn.manifest,
  ])
}

data "helm_template" "longhorn" {
  namespace    = "longhorn-system"
  name         = "longhorn"
  repository   = "https://charts.longhorn.io"
  chart        = "longhorn"
  version      = var.longhorn_version
  kube_version = var.kubernetes_version
  api_versions = []
}