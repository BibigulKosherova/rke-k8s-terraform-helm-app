provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "api" {
  name       = "api"
  chart      = 
  namespace  = "default"
  values     = 
}

resource "helm_release" "web" {
  name       = "web"
  chart      = 
  namespace  = "default"
  values     = 
}

resource "helm_release" "mysql" {
  name       = "mysql"
  chart      = 
  namespace  = "default"
  values     = 
}
