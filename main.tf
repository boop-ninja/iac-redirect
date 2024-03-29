locals {
  app         = "redirect-server"
  namespace   = kubernetes_namespace.name.metadata[0].name
  domain_name = "links.boop.ninja"

}

resource "kubernetes_namespace" "name" {
  metadata {
    name = local.app
  }
}

variable "redirects" {
  default = ""
}
variable "default_url" {
  default = ""
}
resource "kubernetes_deployment" "i" {
  depends_on = [kubernetes_namespace.name]
  metadata {
    name      = local.app
    namespace = local.namespace
    labels = {
      app = local.app
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.app
      }
    }
    template {
      metadata {
        labels = {
          app = local.app
        }
      }
      spec {
        container {
          name  = "redirect-agent"
          image = "mbround18/redirect:latest"

          env {
            name  = "DEFAULT_ENDPOINT"
            value = var.default_url
          }

          env {
            name  = "REDIRECTS"
            value = var.redirects
          }

          port {
            container_port = 8000
            name           = "web"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "i" {
  metadata {
    name      = local.app
    namespace = local.namespace
  }

  spec {
    selector = {
      app = local.app
    }

    port {
      name        = "web"
      port        = 8000
      target_port = 8000
    }

  }
}
resource "kubernetes_ingress_v1" "i" {
  depends_on = [
    kubernetes_namespace.name,
    kubernetes_deployment.i
  ]
  metadata {
    name      = local.app
    namespace = local.namespace
    annotations = {
      "cert-manager.io/cluster-issuer" : "letsencrypt-prod"
    }
  }
  spec {
    tls {
      secret_name = "${local.app}-cert"
      hosts = [
        local.domain_name
      ]
    }
    rule {
      host = local.domain_name
      http {
        path {
          path = "/"

          backend {
            service {
              name = kubernetes_service.i.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}




