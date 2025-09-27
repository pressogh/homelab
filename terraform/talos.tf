resource "talos_machine_secrets" "talos" {
  talos_version = "v${var.talos_version}"
}

data "talos_machine_configuration" "controller" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_secrets    = talos_machine_secrets.talos.machine_secrets
  machine_type       = "controlplane"
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version
  examples           = false
  docs               = false
  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "eth0"
              vip = {
                ip = var.cluster_vip
              }
            }
          ]
        }
      }
    }),
    yamlencode({
      cluster = {
        inlineManifests = [
          {
            name     = "spin"
            contents = <<-EOF
            apiVersion: node.k8s.io/v1
            kind: RuntimeClass
            metadata:
              name: wasmtime-spin-v2
            handler: spin
            EOF
          },
          {
            name = "cilium"
            contents = local.cilium_manifest
          },
          {
            name = "cert-manager"
            contents = local.cert_manager_manifest
          },
          {
            name     = "trust-manager"
            contents = local.trust_manager_manifest
          },
          {
            name = "gateway"
            contents = local.gateway_manifest
          },
          {
            name = "longhorn"
            contents = local.longhorn_manifest
          },
        ],
      },
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_secrets    = talos_machine_secrets.talos.machine_secrets
  machine_type       = "worker"
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version
  examples           = false
  docs               = false
  config_patches = [
    yamlencode(local.common_machine_config),
  ]
}

data "talos_client_configuration" "talos" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoints            = [for node in local.controller_nodes : node.address]
}

resource "talos_machine_configuration_apply" "controller" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  count                       = var.controller_count
  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration
  endpoint                    = local.controller_nodes[count.index].address
  node                        = local.controller_nodes[count.index].address
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = local.controller_nodes[count.index].name
        }
      }
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [proxmox_virtual_environment_vm.worker]

  count                       = var.worker_count
  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = local.worker_nodes[count.index].address
  node                        = local.worker_nodes[count.index].address
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = local.worker_nodes[count.index].name
        }
      }
    }),
  ]
}

resource "talos_machine_bootstrap" "talos" {
  depends_on = [
    talos_machine_configuration_apply.controller,
    talos_machine_configuration_apply.worker,
  ]

  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoint             = local.controller_nodes[0].address
  node                 = local.controller_nodes[0].address
}

data "talos_cluster_health" "talos" {
  depends_on = [talos_machine_bootstrap.talos]

  client_configuration = data.talos_client_configuration.talos.client_configuration
  control_plane_nodes  = [for node in local.controller_nodes : node.address]
  worker_nodes         = [for node in local.worker_nodes : node.address]
  endpoints            = data.talos_client_configuration.talos.endpoints
  timeouts = {
    read = "10m"
  }
}

resource "talos_cluster_kubeconfig" "talos" {
  depends_on = [data.talos_cluster_health.talos]

  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoint             = local.controller_nodes[0].address
  node                 = local.controller_nodes[0].address
}