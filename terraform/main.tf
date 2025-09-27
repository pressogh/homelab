locals {
  controller_nodes = {
    for i, ctrl in var.controllers : "controller-0${i + 1}" => {
      node    = ctrl.node
      address = cidrhost(var.cluster_node_network, var.cluster_node_network_first_controller_hostnum + i)
      vm_id   = var.cluster_node_network_first_controller_hostnum + i
    }
  }
  worker_nodes = {
    for i, wkr in var.workers : "worker-0${i + 1}" => {
      node    = wkr.node
      address = cidrhost(var.cluster_node_network, var.cluster_node_network_first_worker_hostnum + i)
      vm_id   = var.cluster_node_network_first_worker_hostnum + i
    }
  }

  common_machine_config = {
    machine = {
      features = {
        kubePrism = {
          enabled = true
          port    = 7445
        }
        hostDNS = {
          enabled              = true
          forwardKubeDNSToHost = true
        }
      }
    }
    cluster = {
      discovery = {
        enabled = false
        registries = {
          kubernetes = {
            disabled = true
          }
          service = {
            disabled = true
          }
        }
      }
      network = {
        cni = {
          name = "none"
        }
      }
      proxy = {
        disabled = true
      }
    }
  }
}