terraform {
  required_version = ">= 1.10.6"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}