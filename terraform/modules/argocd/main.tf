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

resource "kubectl_manifest" "bootstrap-root-app" {
  depends_on = [helm_release.argocd]

  yaml_body = file("${path.root}/../k8s/argocd/bootstrap/root-app.yaml")
}
