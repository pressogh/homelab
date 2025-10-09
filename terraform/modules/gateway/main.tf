resource "kubernetes_namespace" "gateway-public" {
  metadata {
    name = "gateway-public"
    labels = {
      expose = "public"
    }
  }
}

resource "kubernetes_namespace" "gateway-internal" {
  metadata {
    name = "gateway-internal"
    labels = {
      expose = "internal"
    }
  }
}

resource "kubectl_manifest" "gateway-public" {
  depends_on = [kubernetes_namespace.gateway-public]

  yaml_body = yamlencode({
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

        # HTTPS apex(TLS Terminate)
        {
          name     = "https-apex-terminate"
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

        # HTTPS wildcard(TLS Terminate)
        {
          name     = "https-wild-terminate"
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
        },

        # HTTPS apex(TLS Passthrough)
        {
          name = "https-apex-passthrough"
          hostname = var.public_domain
          port = 443
          protocol = "TLS"
          tls = {
            mode = "Passthrough"
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

        # HTTPS wildcard(TLS Passthrough)
        {
          name = "https-wild-passthrough"
          hostname = "*.${var.public_domain}"
          port = 443
          protocol = "TLS"
          tls = {
            mode = "Passthrough"
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
      ]
    }
  })
}

resource "kubectl_manifest" "gateway-internal" {
  depends_on = [kubernetes_namespace.gateway-internal]

  yaml_body = yamlencode({
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
          name     = "https-apex-terminate"
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
          name     = "https-wild-terminate"
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
          name = "https-apex-passthrough"
          hostname = var.internal_domain
          port = 443
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
        },
        {
          name = "https-wild-passthrough"
          hostname = "*.${var.internal_domain}"
          port = 443
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
        },

        {
          name     = "es-https-apex"
          hostname = "es.${var.internal_domain}"
          port     = 9200
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
      ]
    }
  })
}

resource "kubectl_manifest" "http-redirect-public" {
  depends_on = [kubectl_manifest.gateway-public]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "http-redirect"
      namespace = kubernetes_namespace.gateway-public.metadata[0].name
    }
    spec = {
      hostnames = [var.public_domain, "*.${var.public_domain}"]
      parentRefs = [
        {
          name      = "public-gw"
          namespace = "gateway-public"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          filters = [
            {
              type = "RequestRedirect"
              requestRedirect = {
                scheme = "https"
                port   = 443
              }
            }
          ]
          backendRefs = []
        }
      ]
    }
  })
}

resource "kubectl_manifest" "http-redirect-internal" {
  depends_on = [kubectl_manifest.gateway-internal]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "http-redirect"
      namespace = kubernetes_namespace.gateway-internal.metadata[0].name
    }
    spec = {
      hostnames = [var.internal_domain, "*.${var.internal_domain}"]
      parentRefs = [
        {
          name      = "internal-gw"
          namespace = "gateway-internal"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          filters = [
            {
              type = "RequestRedirect"
              requestRedirect = {
                scheme = "https"
                port   = 443
              }
            }
          ]
          backendRefs = []
        }
      ]
    }
  })
}