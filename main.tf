locals {
  app       = "redirect-server"
  namespace = kubernetes_namespace.name.metadata[0].name
  port      = 8123
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
            name = "web"
          }
        }
      }
    }
  }
}






