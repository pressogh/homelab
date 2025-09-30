locals {
  gateway_namespace_manifests = [
    {
      apiVersion = "v1"
      kind       = "Namespace"
      metadata = {
        name = "gateway-public"
        labels = {
          expose = "public"
        }
      }
    },
    {
      apiVersion = "v1"
      kind       = "Namespace"
      metadata = {
        name = "gateway-internal"
        labels = {
          expose = "internal"
        }
      }
    }
  ]

  gateway_public_manifest = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "public-gw"
      namespace = "gateway-public"
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-dns01-public"
      }
    }
    spec = {
      gatewayClassName = "cilium"
      addresses = [
        {
          type = "IPAddress"
          # TODO: Make this configurable
          value = "192.168.110.220"
        }
      ]
      listeners = [
        {
          name     = "http-apex"
          hostname = var.public_domain
          port     = 80
          protocol = "HTTP"
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "public"
                }
              }
            }
          }
        },
        {
          name     = "http-wild"
          hostname = "*.${var.public_domain}"
          port     = 80
          protocol = "HTTP"
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "public"
                }
              }
            }
          }
        },

        # HTTPS apex
        {
          name     = "https-apex"
          hostname = var.public_domain
          port     = 443
          protocol = "HTTPS"
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = var.public_gw_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "public"
                }
              }
            }
          }
        },

        # HTTPS wildcard
        {
          name     = "https-wild"
          hostname = "*.${var.public_domain}"
          port     = 443
          protocol = "HTTPS"
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = var.public_gw_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "public"
                }
              }
            }
          }
        }
      ]
    }
  })

  gateway_internal_manifest = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "internal-gw"
      namespace = "gateway-internal"
      annotations = {
        "cert-manager.io/cluster-issuer" = "internal-ca"
      }
    }
    spec = {
      gatewayClassName = "cilium"
      addresses = [
        {
          type = "IPAddress"
          # TODO: Make this configurable
          value = "192.168.110.221"
        }
      ]
      listeners = [
        {
          name     = "http-apex"
          hostname = var.internal_domain
          port     = 80
          protocol = "HTTP"
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "internal"
                }
              }
            }
          }
        },
        {
          name     = "http-wild"
          hostname = "*.${var.internal_domain}"
          port     = 80
          protocol = "HTTP"
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "internal"
                }
              }
            }
          }
        },

        {
          name     = "https-apex"
          hostname = var.internal_domain
          port     = 443
          protocol = "HTTPS"
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = var.internal_gw_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "internal"
                }
              }
            }
          }
        },
        {
          name     = "https-wild"
          hostname = "*.${var.internal_domain}"
          port     = 443
          protocol = "HTTPS"
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = var.internal_gw_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "internal"
                }
              }
            }
          }
        },

        {
          name     = "es-tls"
          hostname = "elasticsearch.home.arpa"
          port     = 443
          protocol = "TLS"
          tls = {
            mode = "Passthrough"
          }
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  expose = "internal"
                }
              }
            }
          }
        }
      ]
    }
  })

  gateway_namespace_manifest = join("---\n", [for ns in local.gateway_namespace_manifests : yamlencode(ns)])

  gateway_manifest = join(
    "---\n",
    [
      local.gateway_namespace_manifest,
      local.gateway_public_manifest,
      local.gateway_internal_manifest,
    ]
  )
}