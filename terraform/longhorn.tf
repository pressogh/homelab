locals {
  longhorn_domain    = "longhorn.${var.public_domain}"
  longhorn_namespace = "longhorn-system"

  longhorn_namespace_manifest = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = local.longhorn_namespace
      labels = {
        "pod-security.kubernetes.io/enforce" = "privileged"
        "expose"                             = "public"
      }
    }
  })

  longhorn_http_route_manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "longhorn-route"
      namespace = local.longhorn_namespace
    }
    spec = {
      parentRefs = [
        {
          name      = "public-gw"
          namespace = "gateway-public"
        }
      ]
      hostnames = [local.longhorn_domain]
      rules = [
        {
          matches     = [{ path = { type = "PathPrefix", value = "/" } }]
          backendRefs = [{ name = "longhorn-frontend", port = 80 }]
        }
      ]
    }
  }

  longhorn_manifest = join("---\n", [
    local.longhorn_namespace_manifest,
    data.helm_template.longhorn.manifest,
    yamlencode(local.longhorn_http_route_manifest),
  ])
}

data "helm_template" "longhorn" {
  namespace    = local.longhorn_namespace
  name         = "longhorn"
  repository   = "https://charts.longhorn.io"
  chart        = "longhorn"
  version      = var.longhorn_version
  kube_version = var.kubernetes_version
  api_versions = []
}