resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "expose" = "public"
    }
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.argocd_version

  values = [yamlencode({
    global = {
      domain = var.argocd_domain
    }
    server = {
      ingress = {
        enabled = false
      }
    }
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

resource "kubectl_manifest" "http-route" {
  depends_on = [helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd-route"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name      = "public-gw"
          namespace = "gateway-public"
        }
      ]
      hostnames = [var.argocd_domain]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "argocd-server"
              port = 80
            }
          ]
        }
      ]
    }
  })
}
