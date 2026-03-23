locals {
  external_secrets_namespace_manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "external-secrets"
    }
  }

  bitwarden_credentials_manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "bitwarden-credentials"
      namespace = "external-secrets"
    }
    type = "Opaque"
    stringData = {
      token = var.bitwarden_access_token
    }
  }
}
