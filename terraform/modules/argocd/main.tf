resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "expose" = "internal"
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
        "server.insecure" = "true"
      }
    }
  })]
}

resource "kubectl_manifest" "argocd-network-policy" {
  depends_on = [helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNetworkPolicy"
    metadata = {
      name      = "argocd-security"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      endpointSelector = {
        matchLabels = {
          "app.kubernetes.io/part-of" = "argocd"
        }
      }

      ingress = [
        {
          fromEntities = ["ingress"]
          toPorts = [
            {
              ports = [
                { port = "8080", protocol = "TCP" },
                { port = "8083", protocol = "TCP" }
              ]
            }
          ]
        },
        {
          fromEndpoints = [
            {
              matchLabels = {
                "app.kubernetes.io/part-of" = "argocd"
              }
            }
          ]
        }
      ]

      egress = [
        {
          toEntities = ["kube-apiserver"]
        },
        {
          toEndpoints = [
            {
              matchLabels = {
                "app.kubernetes.io/part-of" = "argocd"
              }
            }
          ]
        },
        {
          toEndpoints = [
            {
              matchLabels = {
                "io.kubernetes.pod.namespace" = "kube-system"
                "k8s-app"                     = "kube-dns"
              }
            }
          ]
          toPorts = [
            {
              ports = [
                { port = "53", protocol = "UDP" }
              ]
            }
          ]
        },
        {
          toEntities = ["world"]
          toPorts = [
            {
              ports = [
                { port = "443", protocol = "TCP" },
                { port = "22", protocol = "TCP" }
              ]
            }
          ]
        }
      ]
    }
  })
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
      hostnames = [var.argocd_domain]
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
              name = "argocd-server"
              port = 80
            }
          ]
        }
      ]
    }
  })
}

resource "kubectl_manifest" "apps" {
  count = var.argocd_default_apps == null ? 0 : 1

  depends_on = [helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "apps"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.argocd_default_apps.git_url
        path           = var.argocd_default_apps.path
        targetRevision = var.argocd_default_apps.target_revision
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.argocd.metadata[0].name
      }
      syncPolicy = {
        automated = {
          enabled  = true
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true",
        ]
      }
    }
  })
}
