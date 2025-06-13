provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "mysql" {
  name       = "mysql"
  chart      = "${path.module}/helm/mysql"
  namespace  = "default"
}

resource "helm_release" "api" {
  name       = "api"
  chart      = "${path.module}/helm/api"
  namespace  = "default"

  values = [
    file("${path.module}/helm/api/values.yaml")
  ]
}

resource "helm_release" "web" {
  name       = "web"
  chart      = "${path.module}/helm/web"
  namespace  = "default"

  values = [
    file("${path.module}/helm/web/values.yaml")
  ]
}
