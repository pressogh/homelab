locals {
  controller_nodes = {
    for i, ctrl in var.controllers : "controller-0${i + 1}" => {
      node    = ctrl.node
      address = cidrhost(var.cluster_node_network, ctrl.vm_id)
      vm_id   = ctrl.vm_id
    }
  }
  worker_nodes = {
    for i, wkr in var.workers : "worker-0${i + 1}" => {
      node    = wkr.node
      address = cidrhost(var.cluster_node_network, wkr.vm_id)
      vm_id   = wkr.vm_id
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