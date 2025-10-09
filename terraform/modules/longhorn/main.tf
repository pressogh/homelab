resource "kubernetes_namespace" "longhorn-system" {
  metadata {
    name = "longhorn-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "expose"                             = "internal"
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
      hostnames = [var.longhorn_domain]
      parentRefs = [
        {
          name        = "internal-gw"
          namespace   = "gateway-internal"
          sectionName = "https-wild-terminate"
        }
      ]
      filters = [
        {
          type = "ResponseHeaderModifier"
          responseHeaderModifier = {
            add = [
              {
                name  = "Strict-Transport-Security"
                value = "max-age=31536000; includeSubDomains; preload"
              },
              {
                name  = "X-Content-Type-Options"
                value = "nosniff"
              },
              {
                name  = "X-Frame-Options"
                value = "DENY"
              }
            ]
          }
        }
      ]
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
