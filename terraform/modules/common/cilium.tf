locals {
  gateway_api_crd_url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml"
  servicemonitor_crd_url = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/refs/tags/v0.85.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"
}
data "http" "gateway_api_crds" {
  url = local.gateway_api_crd_url
}
data "http" "servicemonitor_crd" {
  url = local.servicemonitor_crd_url
}

locals {
  crds_manifest = join("\n---\n", [
    data.http.gateway_api_crds.response_body,
    data.http.servicemonitor_crd.response_body,
  ])

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
      local.crds_manifest,
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
    "gateway.networking.k8s.io/v1",
    "gateway.networking.k8s.io/v1/GatewayClass",
    "monitoring.coreos.com/v1",
    "monitoring.coreos.com/v1/ServiceMonitor",
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
      name  = "hubble.enabled"
      value = "true"
    },
    {
      name  = "hubble.relay.enabled"
      value = "true"
    },
    {
      name  = "hubble.ui.enabled"
      value = "true"
    },
    {
      name  = "hubble.export.static.enabled"
      value = "true"
    },
    {
      name  = "hubble.export.static.filePath"
      value = "/var/run/cilium/hubble/events.log"
    },
    {
      name  = "prometheus.enabled"
      value = "true"
    },
    {
      name  = "operator.prometheus.enabled"
      value = "true"
    },
    {
      name  = "hubble.metrics.enableOpenMetrics"
      value = "true"
    },
    {
      name  = "hubble.metrics.enabled"
      value = "{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction}"
    },
    {
      name  = "prometheus.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "operator.prometheus.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "hubble.relay.prometheus.enabled"
      value = "true"
    },
    {
      name  = "hubble.relay.prometheus.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "prometheus.serviceMonitor.labels.release"
      value = "kube-prometheus-stack"
    },
    {
      name  = "operator.prometheus.serviceMonitor.labels.release"
      value = "kube-prometheus-stack"
    },
    {
      name  = "hubble.relay.prometheus.serviceMonitor.labels.release"
      value = "kube-prometheus-stack"
    },
    {
      name  = "prometheus.metricsService"
      value = "true"
    },
    {
      name  = "operator.prometheus.metricsService"
      value = "true"
    },
  ]
}