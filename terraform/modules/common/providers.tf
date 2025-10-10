terraform {
  required_version = ">= 1.10.6"

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
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
  }
}
