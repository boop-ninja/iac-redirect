terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "boop-ninja"

    workspaces {
      name = "iac-redirect"
    }
  }
}
