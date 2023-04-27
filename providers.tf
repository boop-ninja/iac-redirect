variable "kube_key" {
  default = ""
}
variable "kube_crt" {
  default = ""
}
variable "kube_host" {
  default = ""
}
provider "kubernetes" {
  host               = var.kube_host
  client_certificate = base64decode(var.kube_crt)
  client_key         = base64decode(var.kube_key)
  insecure           = true

  config_context = "default"

  experiments {
    manifest_resource = true
  }
}
