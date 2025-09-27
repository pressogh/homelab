locals {
  cert_manager_namespace_manifest = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "cert-manager"
    }
  })

  cert_manager_public_manifests = [
    {
      apiVersion = "v1"
      kind       = "Secret"
      metadata   = {
        name = "cloudflare-api-token",
        namespace = "cert-manager"
      }
      type       = "Opaque"
      stringData = { api-token = var.cf_api_token }
    },
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
            selector = {
              dnsZones = [var.public_domain]
            }
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = "cloudflare-api-token",
                  key = "api-token"
                }
              }
            }
          }]
        }
      }
    },
  ]

  cert_manager_internal_ca_manifests = [
    {
      apiVersion = "cert-manager.io/v1"
      kind       = "ClusterIssuer"
      metadata = {
        name = "internal-selfsigned"
      }
      spec = {
        selfSigned = {}
      }
    },
    {
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
    },
    {
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
    }
  ]

  cert_manager_public_manifest = join(
    "---\n",
    [for d in local.cert_manager_public_manifests : yamlencode(d)]
  )
  cert_manager_internal_ca_manifest = join("---\n", [for d in local.cert_manager_internal_ca_manifests : yamlencode(d)])

  cert_manager_manifest = join(
    "---\n",
    [
      local.cert_manager_namespace_manifest,
      data.helm_template.cert_manager.manifest,
      local.cert_manager_public_manifest,
      local.cert_manager_internal_ca_manifest,
    ]
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