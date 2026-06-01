variable "proxmox_pve_nodes" {
  type = set(object({
    name    = string
    address = string
  }))
  description = "Set of Proxmox nodes with their names and addresses."
}

variable "talos_version" {
  type    = string
  default = "1.13.3"
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.talos_version))
    error_message = "Must be a version number."
  }
}
variable "talos_disk_image_schematic_id" {
  type        = string
  default     = "88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b" # schematic is content-hash of extension set; version-independent (verify on factory.talos.dev for v1.13.3)
  description = "The schematic ID of the Talos disk image to use."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.36.1"
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

variable "cilium_version" {
  type        = string
  default     = "1.19.4"
  description = "The version of Cilium to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.cilium_version))
    error_message = "Must be a version number."
  }
}

variable "bitwarden_access_token" {
  type        = string
  description = "Bitwarden Secrets Manager access token for External Secrets Operator."
  sensitive   = true
}
