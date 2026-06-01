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
    node  = string
  }))
  default     = []
  description = "List of controller nodes with their Proxmox node names and VM ID."
}
variable "workers" {
  type = list(object({
    vm_id  = number
    node   = string
    memory = number
  }))
  default     = []
  description = "List of worker nodes with their Proxmox node names, VM ID, and dedicated memory (MiB)."
}

variable "internal_domain" {
  type        = string
  description = "The internal domain for ArgoCD and other internal services."
}
variable "bitwarden_access_token" {
  type        = string
  description = "Bitwarden Secrets Manager access token for External Secrets Operator."
  sensitive   = true
}
