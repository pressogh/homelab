module "common" {
  source = "./modules/common"

  providers = {
    helm = helm.template
  }

  proxmox_pve_nodes = var.proxmox_pve_nodes

  talos_version                 = "1.13.3"
  talos_disk_image_schematic_id = "88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b"
  kubernetes_version            = "1.36.1"

  cluster_name                                     = var.cluster_name
  cluster_vip                                      = var.cluster_vip
  cluster_endpoint                                 = var.cluster_endpoint
  cluster_node_network_gateway                     = var.cluster_node_network_gateway
  cluster_node_network                             = var.cluster_node_network
  cluster_node_network_vlan_id                     = var.cluster_node_network_vlan_id
  cluster_node_network_load_balancer_first_hostnum = var.cluster_node_network_load_balancer_first_hostnum
  cluster_node_network_load_balancer_last_hostnum  = var.cluster_node_network_load_balancer_last_hostnum

  controllers = var.controllers
  workers     = var.workers

  cilium_version         = "1.19.4"
  bitwarden_access_token = var.bitwarden_access_token
}

module "argocd" {
  source = "./modules/argocd"

  providers = {
    helm       = helm.workloads
    kubernetes = kubernetes
    kubectl    = kubectl
  }

  argocd_version = "9.5.17"
  argocd_domain  = "argocd.${var.internal_domain}"
}
