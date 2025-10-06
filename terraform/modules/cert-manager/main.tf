resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  depends_on = [kubernetes_namespace.cert-manager]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert-manager.metadata[0].name
  version    = var.cert_manager_version
  set = [
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "config.apiVersion"
      value = "controller.config.cert-manager.io/v1alpha1"
    },
    {
      name  = "config.kind"
      value = "ControllerConfiguration"
    },
    {
      name  = "config.enableGatewayAPI"
      value = "true"
    },
  ]
}

resource "kubernetes_secret" "cloudflare-api-token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
  }
  type = "Opaque"
  data = {
    "api-token" = var.cf_api_token
  }
}

resource "kubectl_manifest" "public-cluster-issuer" {
  depends_on = [helm_release.cert-manager, kubernetes_secret.cloudflare-api-token]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns01-public"
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-dns01-public-account-key"
        }
        solvers = [{
          selector = {
            dnsZones = [var.public_domain]
          }
          dns01 = {
            cloudflare = {
              apiTokenSecretRef = {
                name = "cloudflare-api-token",
                key  = "api-token"
              }
            }
          }
        }]
      }
    }
  })
}

resource "kubectl_manifest" "internal-selfsigned-cluster-issuer" {
  depends_on = [helm_release.cert-manager]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "internal-selfsigned"
    }
    spec = {
      selfSigned = {}
    }
  })
}

resource "kubectl_manifest" "internal-root-ca-certificate" {
  depends_on = [kubectl_manifest.internal-selfsigned-cluster-issuer]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "internal-root-ca"
      namespace = "cert-manager"
    }
    spec = {
      isCA       = true
      commonName = "internal-root-ca"
      secretName = "internal-root-ca"
      privateKey = {
        algorithm = "ECDSA"
        size      = 256
      }
      issuerRef = {
        name  = "internal-selfsigned"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  })
}

resource "kubectl_manifest" "internal-ca-cluster-issuer" {
  depends_on = [kubectl_manifest.internal-root-ca-certificate]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "internal-ca"
    }
    spec = {
      ca = {
        secretName = "internal-root-ca"
      }
    }
  })
}

resource "helm_release" "trust-manager" {
  depends_on = [helm_release.cert-manager]

  namespace  = kubernetes_namespace.cert-manager.metadata[0].name
  name       = "trust-manager"
  repository = "https://charts.jetstack.io"
  chart      = "trust-manager"
  version    = "0.19.0"
  set = [
    {
      name  = "secretTargets.enabled"
      value = "true"
    },
    {
      name  = "secretTargets.authorizedSecretsAll"
      value = "true"
    },
  ]
}

resource "kubectl_manifest" "trust-bundle" {
  depends_on = [helm_release.trust-manager, kubectl_manifest.internal-root-ca-certificate]

  yaml_body = yamlencode({
    apiVersion = "trust.cert-manager.io/v1alpha1"
    kind       = "Bundle"
    metadata = {
      name = "internal-ca-bundle"
    }
    spec = {
      sources = [
        {
          secret = {
            name = "internal-root-ca"
            key  = "tls.crt"
          }
        }
      ]
      target = {
        configMap = {
          key = "ca.crt"
        }
        namespaceSelector = {
          matchLabels = {
            "cert-manager.io/inject-trust" = "true"
          }
        }
      }
    }
  })
}