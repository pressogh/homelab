terraform {
  required_version = ">= 1.10.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.119.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.3"
    }
  }
}
