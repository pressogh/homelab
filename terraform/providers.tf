terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_pve_endpoint
  ssh {
    dynamic "node" {
      for_each = var.proxmox_pve_nodes

      content {
        name    = node.value.name
        address = node.value.address
      }
    }

    username = var.proxmox_pve_username
    agent    = true
  }
  api_token = "${var.proxmox_pve_api_token_id}=${var.proxmox_pve_api_token_secret}"
  insecure  = var.proxmox_pve_insecure
}

provider "talos" {}

provider "helm" {
  alias = "template"
}

provider "helm" {
  alias = "workloads"
  kubernetes = {
    host                   = module.common.kube_client_config.host
    cluster_ca_certificate = base64decode(module.common.kube_client_config.ca_certificate)
    client_key             = base64decode(module.common.kube_client_config.client_key)
    client_certificate     = base64decode(module.common.kube_client_config.client_certificate)
  }
}

provider "kubernetes" {
  host                   = module.common.kube_client_config.host
  cluster_ca_certificate = base64decode(module.common.kube_client_config.ca_certificate)
  client_key             = base64decode(module.common.kube_client_config.client_key)
  client_certificate     = base64decode(module.common.kube_client_config.client_certificate)
}

provider "kubectl" {
  load_config_file       = false
  host                   = module.common.kube_client_config.host
  cluster_ca_certificate = base64decode(module.common.kube_client_config.ca_certificate)
  client_key             = base64decode(module.common.kube_client_config.client_key)
  client_certificate     = base64decode(module.common.kube_client_config.client_certificate)
}