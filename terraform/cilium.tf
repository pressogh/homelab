locals {
  cilium_external_lb_manifests = [
    {
      apiVersion = "cilium.io/v2alpha1"
      kind       = "CiliumL2AnnouncementPolicy"
      metadata = {
        name = "external"
      }
      spec = {
        loadBalancerIPs = true
        externalIPs     = true
        interfaces = [
          "eth0",
        ]
        nodeSelector = {
          matchExpressions = [
            {
              key      = "node-role.kubernetes.io/control-plane"
              operator = "DoesNotExist"
            },
          ]
        }
      }
    },
    {
      apiVersion = "cilium.io/v2alpha1"
      kind       = "CiliumLoadBalancerIPPool"
      metadata = {
        name = "external"
      }
      spec = {
        blocks = [
          {
            start = cidrhost(var.cluster_node_network, var.cluster_node_network_load_balancer_first_hostnum)
            stop  = cidrhost(var.cluster_node_network, var.cluster_node_network_load_balancer_last_hostnum)
          },
        ]
      }
    },
  ]

  cilium_external_lb_manifest = join("---\n", [for d in local.cilium_external_lb_manifests : yamlencode(d)])
  cilium_manifest = join(
    "---\n",
    [
      data.helm_template.cilium.manifest,
      local.cilium_external_lb_manifest,
    ]
  )
}

data "helm_template" "cilium" {

  namespace    = "kube-system"
  name         = "cilium"
  repository   = "https://helm.cilium.io"
  chart        = "cilium"
  version      = var.cilium_version
  kube_version = var.kubernetes_version
  api_versions = [
    "gateway.networking.k8s.io/v1/GatewayClass"
  ]
  set = [
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    {
      name  = "kubeProxyReplacement"
      value = "true"
    },
    {
      name  = "securityContext.capabilities.ciliumAgent"
      value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    },
    {
      name  = "securityContext.capabilities.cleanCiliumState"
      value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    },
    {
      name  = "cgroup.autoMount.enabled"
      value = "false"
    },
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },
    {
      name  = "k8sServiceHost"
      value = "localhost"
    },
    {
      name  = "k8sServicePort"
      value = local.common_machine_config.machine.features.kubePrism.port
    },
    {
      name  = "l2announcements.enabled"
      value = "true"
    },
    {
      name  = "devices"
      value = "{eth0}"
    },
    {
      name  = "gatewayAPI.enabled"
      value = "true"
    },
    {
      name  = "envoy.enabled"
      value = "true"
    },
    {
      name  = "hubble.relay.enabled"
      value = "true"
    },
    {
      name  = "hubble.ui.enabled"
      value = "true"
    }
  ]
}