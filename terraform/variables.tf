variable "proxmox_pve_endpoint" {
  type        = string
  description = "Endpoint for the Proxmox provider."
}
variable "proxmox_pve_nodes" {
  type = set(object({
    name    = string
    address = string
  }))
  description = "Set of Proxmox nodes with their names and addresses."
}
variable "proxmox_pve_username" {
  type        = string
  description = "Proxmox username."
  sensitive   = true
}
variable "proxmox_pve_api_token_id" {
  type        = string
  description = "The Proxmox API token ID."
  sensitive   = true
}
variable "proxmox_pve_api_token_secret" {
  type        = string
  description = "The Proxmox API token secret."
  sensitive   = true
}
variable "proxmox_pve_insecure" {
  type        = bool
  default     = false
  description = "Whether to skip TLS verification for the Proxmox provider."
}

variable "talos_version" {
  type    = string
  default = "1.11.1"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}
variable "talos_disk_image_schematic_id" {
  type        = string
  default     = "88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b" # 1.11.1
  description = "The schematic ID of the Talos disk image to use."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.34.1"
  description = "The version of Kubernetes to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.kubernetes_version))
    error_message = "Must be a version number."
  }
}

variable "cluster_name" {
  type        = string
  description = "The name to provide for the Talos cluster."
  default     = "homelab"
}
variable "cluster_vip" {
  type        = string
  description = "The virtual IP (VIP) address of the Kubernetes API server. Ensure it is synchronized with the 'cluster_endpoint' variable."
  default     = "192.168.110.79"
}
variable "cluster_endpoint" {
  type        = string
  description = "The virtual IP (VIP) endpoint of the Kubernetes API server. Ensure it is synchronized with the 'cluster_vip' variable."
  default     = "https://192.168.110.79:6443"
}
variable "cluster_node_network_gateway" {
  type        = string
  description = "The IP network gateway of the cluster nodes"
  default     = "192.168.110.1"
}
variable "cluster_node_network" {
  type        = string
  description = "The IP network of the cluster nodes"
  default     = "192.168.110.0/24"
}
variable "cluster_node_network_vlan_id" {
  type        = number
  description = "The VLAN ID of the cluster node network"
  default     = 110
}
variable "cluster_node_network_load_balancer_first_hostnum" {
  type        = number
  description = "The hostnum of the first load balancer host"
  default     = 220
}
variable "cluster_node_network_load_balancer_last_hostnum" {
  type        = number
  description = "The hostnum of the last load balancer host"
  default     = 250
}

variable "controllers" {
  type = list(object({
    vm_id = number
    node = string
  }))
  default     = []
  description = "List of controller nodes with their Proxmox node names and VM ID."
}
variable "workers" {
  type = list(object({
    vm_id = number
    node = string
  }))
  default     = []
  description = "List of worker nodes with their Proxmox node names and VM ID."
}

variable "cilium_version" {
  type        = string
  default     = "1.18.2"
  description = "The version of Cilium to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.cilium_version))
    error_message = "Must be a version number."
  }
}

variable "cert_manager_version" {
  type        = string
  default     = "1.18.2"
  description = "The version of cert-manager to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.cert_manager_version))
    error_message = "Must be a version number."
  }
}
variable "acme_email" {
  type        = string
  description = "The email to use for ACME registration."
}
variable "public_domain" {
  type        = string
  description = "The public domain to use for ACME DNS-01 challenges."
}
variable "internal_domain" {
  type        = string
  description = "The internal domain to use for ACME DNS-01 challenges."
}
variable "cf_api_token" {
  type        = string
  description = "The Cloudflare API token to use for DNS-01 challenges."
  sensitive   = true
}
variable "public_gw_secret_name" {
  type        = string
  description = "The public gateway secret name."
  default     = "public-gw-tls"
}
variable "internal_gw_secret_name" {
  type        = string
  description = "The internal gateway secret name."
  default     = "internal-gw-tls"
}

variable "longhorn_version" {
  type        = string
  default     = "1.10.0"
  description = "The version of Longhorn to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.longhorn_version))
    error_message = "Must be a version number."
  }
}

variable "argocd_version" {
  type        = string
  default     = "8.5.7"
  description = "The version of Argo CD to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.argocd_version))
    error_message = "Must be a version number."
  }
}