locals {
  cert_manager_cloudflare_manifests = [
    # Cloudflare API Token Secrets
    {
      apiVersion = "v1"
      kind       = "Secret"
      metadata   = { name = "cloudflare-token-public", namespace = "cert-manager" }
      type       = "Opaque"
      stringData = { api-token = var.cf_token_public }
    },
    {
      apiVersion = "v1"
      kind       = "Secret"
      metadata   = { name = "cloudflare-token-internal", namespace = "cert-manager" }
      type       = "Opaque"
      stringData = { api-token = var.cf_token_internal }
    },

    # ClusterIssuer for PUBLIC domain(s)
    {
      apiVersion = "cert-manager.io/v1"
      kind       = "ClusterIssuer"
      metadata   = { name = "letsencrypt-dns01-public" }
      spec = {
        acme = {
          email               = var.acme_email
          server              = "https://acme-v02.api.letsencrypt.org/directory"
          privateKeySecretRef = { name = "letsencrypt-dns01-public-account-key" }
          solvers = [{
            selector = { dnsZones = [var.public_domain] }
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = { name = "cloudflare-token-public", key = "api-token" }
              }
            }
          }]
        }
      }
    },

    # ClusterIssuer for INTERNAL domain(s)
    {
      apiVersion = "cert-manager.io/v1"
      kind       = "ClusterIssuer"
      metadata   = { name = "letsencrypt-dns01-internal" }
      spec = {
        acme = {
          email               = var.acme_email
          server              = "https://acme-v02.api.letsencrypt.org/directory"
          privateKeySecretRef = { name = "letsencrypt-dns01-internal-account-key" }
          solvers = [{
            selector = { dnsZones = [var.internal_domain] }
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = { name = "cloudflare-token-internal", key = "api-token" }
              }
            }
          }]
        }
      }
    }
  ]

  cert_manager_cloudflare_manifest = join(
    "---\n",
    [for d in local.cert_manager_cloudflare_manifests : yamlencode(d)]
  )
}

data "helm_template" "cert_manager" {
  namespace    = "cert-manager"
  name         = "cert-manager"
  repository   = "https://charts.jetstack.io"
  chart        = "cert-manager"
  version      = var.cert_manager_version
  kube_version = var.kubernetes_version
  api_versions = []
  set = [
    {
      name  = "installCRDs"
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