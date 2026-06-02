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
        controllerManager = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
        scheduler = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
        etcd = {
          extraArgs = {
            listen-metrics-urls = "http://0.0.0.0:2381"
          }
        }
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
            name     = "cilium"
            contents = local.cilium_manifest
          },
          {
            name     = "external-secrets-namespace"
            contents = yamlencode(local.external_secrets_namespace_manifest)
          },
          {
            name     = "bitwarden-credentials"
            contents = yamlencode(local.bitwarden_credentials_manifest)
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

  for_each = local.controller_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration
  endpoint                    = each.value.address
  node                        = each.value.address
  config_patches = [
    # Talos 1.13 generates a `HostnameConfig` document (auto: stable) and
    # rejects the legacy `machine.network.hostname` alongside it. Set the static
    # hostname via HostnameConfig and disable auto generation (auto: off).
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      auto       = "off"
      hostname   = each.key
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [proxmox_virtual_environment_vm.worker]

  for_each = local.worker_nodes

  client_configuration        = talos_machine_secrets.talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = each.value.address
  node                        = each.value.address
  config_patches = [
    yamlencode({
      machine = {
        sysctls = {
          "vm.max_map_count" = 262144
          "vm.nr_hugepages"  = 1024
        }
        kernel = {
          modules = [
            { name = "nvme_tcp" },
            { name = "vfio_pci" }
          ]
        }
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options = [
                "bind",
                "rshared",
                "rw"
              ]
            }
          ]
        }
      }
    }),
    # Talos 1.13 generates a `HostnameConfig` document (auto: stable) and
    # rejects the legacy `machine.network.hostname` alongside it. Set the static
    # hostname via HostnameConfig and disable auto generation (auto: off).
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      auto       = "off"
      hostname   = each.key
    }),
  ]
}

resource "talos_machine_bootstrap" "talos" {
  depends_on = [
    talos_machine_configuration_apply.controller,
    talos_machine_configuration_apply.worker,
  ]

  client_configuration = talos_machine_secrets.talos.client_configuration
  endpoint             = values(local.controller_nodes)[0].address
  node                 = values(local.controller_nodes)[0].address
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
  endpoint             = values(local.controller_nodes)[0].address
  node                 = values(local.controller_nodes)[0].address
}
