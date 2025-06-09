terraform {
  required_providers {
    rke = {
      source  = "rancher/rke"
      version = "1.4.0"
    }
  }
}

provider "rke" {}


data "terraform_remote_state" "vms" {
  backend = "local"
  config = {
    path = "../terraform-vms/terraform.tfstate"
  }
}


locals {
  public_ips = data.terraform_remote_state.vms.outputs.public_ips
}


resource "rke_cluster" "rke_cluster" {
  enable_cri_dockerd = true
  nodes {
    address = local.public_ips[0]
    user    = "rke"
    role    = ["controlplane", "etcd", "worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }

  nodes {
    address = local.public_ips[1]
    user    = "rke"
    role    = ["worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }

  nodes {
    address = local.public_ips[2]
    user    = "rke"
    role    = ["worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }

  ssh_agent_auth     = false
  kubernetes_version = "v1.24.9-rancher1-1"
}


output "kube_config_yaml" {
  value     = rke_cluster.rke_cluster.kube_config_yaml
  sensitive = true
}
