locals {
  argocd_domain    = "argocd.${var.public_domain}"
  argocd_namespace = "argocd"

  argocd_namespace_manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name   = local.argocd_namespace
      labels = { expose = "public" }
    }
  }

  argocd_http_route_manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd-route"
      namespace = local.argocd_namespace
    }
    spec = {
      parentRefs = [
        {
          name      = "public-gw"
          namespace = "gateway-public"
        }
      ]
      hostnames = [local.argocd_domain]
      rules = [
        {
          matches     = [{ path = { type = "PathPrefix", value = "/" } }]
          backendRefs = [{ name = "argocd-server", port = 80 }]
        }
      ]
    }
  }

  argocd_manifest = join(
    "---\n",
    [
      yamlencode(local.argocd_namespace_manifest),
      data.helm_template.argocd.manifest,
      yamlencode(local.argocd_http_route_manifest),
    ]
  )
}

data "helm_template" "argocd" {
  namespace    = local.argocd_namespace
  name         = "argocd"
  repository   = "https://argoproj.github.io/argo-helm"
  chart        = "argo-cd"
  version      = var.argocd_version
  kube_version = var.kubernetes_version
  api_versions = []

  values = [yamlencode({
    global = { domain = local.argocd_domain }
    server = { ingress = { enabled = false } }
    configs = {
      params = {
        "server.insecure"                                = "true"
        "server.repo.server.plaintext"                   = "true"
        "server.dex.server.plaintext"                    = "true"
        "controller.repo.server.plaintext"               = "true"
        "applicationsetcontroller.repo.server.plaintext" = "true"
        "reposerver.disable.tls"                         = "true"
        "dexserver.disable.tls"                          = "true"
      }
    }
  })]
}
