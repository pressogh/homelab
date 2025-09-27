terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.83.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_pve_endpoint
  ssh {
    username = var.proxmox_pve_username
    agent    = true
  }
  api_token = "${var.proxmox_pve_api_token_id}=${var.proxmox_pve_api_token_secret}"
  insecure  = var.proxmox_pve_insecure
}

provider "talos" {}