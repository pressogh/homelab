locals {
  gateways = [
    # ---------- PUBLIC ----------
    {
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

        # (선택) 생성될 LB Service에 전달할 어노테이션 (예: 고정 IP)
        # Gateway API의 표준 필드(spec.infrastructure.annotations)를 사용합니다.
        # infrastructure = {
        #   annotations = {
        #     "lbipam.cilium.io/ips" = "203.0.113.10"  # Cilium LB IPAM 고정 IP 요청
        #   }
        # }

        listeners = [
          {
            name     = "http"
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
    },

    # ---------- INTERNAL ----------
    {
      apiVersion = "gateway.networking.k8s.io/v1"
      kind       = "Gateway"
      metadata = {
        name      = "internal-gw"
        namespace = "gateway-internal"
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-dns01-internal"
        }
      }
      spec = {
        gatewayClassName = "cilium"

        # (선택) 내부 게이트웨이용 고정 IP 요청
        # infrastructure = {
        #   annotations = {
        #     "lbipam.cilium.io/ips" = "198.51.100.20"
        #   }
        # }

        listeners = [
          {
            name     = "https-apex"
            hostname = var.internal_domain # 예: internal.example.com
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
            hostname = "*.${var.internal_domain}" # 예: *.internal.example.com
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
          }
        ]
      }
    }
  ]

  gateways_manifest = join("---\n", [for d in local.gateways : yamlencode(d)])
}