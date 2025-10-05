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