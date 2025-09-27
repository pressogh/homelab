locals {
  trust_manager_manifest = data.helm_template.trust_manager.manifest
}

data "helm_template" "trust_manager" {
  namespace    = "cert-manager"
  name         = "trust-manager"
  repository   = "https://charts.jetstack.io"
  chart        = "trust-manager"
  version      = "0.19.0"
  kube_version = var.kubernetes_version
  api_versions = []
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