resource "kubernetes_namespace" "longhorn-system" {
  metadata {
    name = "longhorn-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "expose"                             = "public"
    }
  }
}

resource "helm_release" "longhorn" {
  depends_on = [kubernetes_namespace.longhorn-system]

  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = kubernetes_namespace.longhorn-system.metadata[0].name
  version    = var.longhorn_version
}

resource "kubectl_manifest" "http-route" {
  depends_on = [helm_release.longhorn]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "longhorn-route"
      namespace = kubernetes_namespace.longhorn-system.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name      = "public-gw"
          namespace = "gateway-public"
        }
      ]
      hostnames = [var.longhorn_domain]
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
              name = "longhorn-frontend"
              port = 80
            }
          ]
        }
      ]
    }
  })
}
