terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = "cluster"
  region  = "nyc3"
  version = "1.30.1-do.0"
  node_pool {
    name       = "node-pool"
    size       = "s-2vcpu-4gb"
    node_count = 3
  }
}

output "cluster_kubeconfig_save_command" {
  value = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.cluster.id}"
}

resource "helm_release" "fleet_crd" {
  name             = "fleet-crd"
  namespace        = "cattle-fleet-system"
  create_namespace = true
  chart            = "fleet-crd"
  repository       = "https://rancher.github.io/fleet-helm-charts/"
  version          = "0.10.0-rc.17"
  wait             = true
}

resource "helm_release" "fleet" {
  name             = "fleet"
  namespace        = "cattle-fleet-system"
  create_namespace = true
  chart            = "fleet"
  repository       = "https://rancher.github.io/fleet-helm-charts/"
  version          = "0.10.0-rc.17"
  wait             = true
}

resource "kubernetes_manifest" "gitrepo" {
  manifest = {
    apiVersion = "fleet.cattle.io/v1alpha1"
    kind       = "GitRepo"
    metadata = {
      name      = "gitrepo"
      namespace = "fleet-local"
    }
    spec = {
      repo  = "https://github.com/drengskapur/gitops-fleet"
      paths = ["manifests"]
    }
  }
}
