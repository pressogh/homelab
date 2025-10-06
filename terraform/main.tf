module "common" {
  source = "./modules/common"

  providers = {
    helm = helm.template
  }

  proxmox_pve_nodes = var.proxmox_pve_nodes

  talos_version                 = var.talos_version
  talos_disk_image_schematic_id = var.talos_disk_image_schematic_id
  kubernetes_version            = var.kubernetes_version

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

  cilium_version = "1.18.2"
}

module "cert-manager" {
  source = "./modules/cert-manager"

  providers = {
    helm       = helm.workloads
    kubernetes = kubernetes
    kubectl    = kubectl
  }

  acme_email    = var.acme_email
  public_domain = var.public_domain
  cf_api_token  = var.cf_api_token

  cert_manager_version  = "1.18.2"
  trust_manager_version = "0.19.0"
}

module "gateway" {
  source = "./modules/gateway"

  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
  }

  public_domain           = var.public_domain
  internal_domain         = var.internal_domain
  public_gw_secret_name   = var.public_gw_secret_name
  internal_gw_secret_name = var.internal_gw_secret_name
}

module "longhorn" {
  source = "./modules/longhorn"

  providers = {
    helm       = helm.workloads
    kubernetes = kubernetes
    kubectl    = kubectl
  }

  longhorn_version = "1.10.0"
  longhorn_domain  = "longhorn.${var.public_domain}"
}

module "argocd" {
  source = "./modules/argocd"

  providers = {
    helm       = helm.workloads
    kubernetes = kubernetes
    kubectl    = kubectl
  }

  argocd_version = "8.5.7"
  argocd_domain  = "argocd.${var.public_domain}"
}