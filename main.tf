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
      port        = 8080
      target_port = "web"
    }

  }
}

resource "kubernetes_manifest" "i" {
  depends_on = [
    kubernetes_namespace.name,
    kubernetes_deployment.i,
    kubernetes_secret.tls
  ]
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = local.app
      namespace = local.namespace
    }

    spec = {
      entryPoints = ["web"]
      routes = [
        {
          kind  = "Rule"
          match = "Host(`${local.domain_name}`)"
          services = [
            {
              kind           = "Service"
              name           = local.app
              namespace      = local.namespace
              passHostHeader = true
              port           = "web"
            }
          ]
        }
      ]
      tls = {
        secretName = kubernetes_secret.tls.metadata[0].name
        domains = [{
          main = local.domain_name
        }]
      }
    }
  }
}





