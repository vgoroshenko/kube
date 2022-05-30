# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

/*data "external" "kubeconfig" {
  program = [
    "bash",
    "../scripts/tfkubevault.sh"]
  query   = {
    secret_endpoint = var.kubeconfig_secret_name
    role_id         = "vault_role_env"
    secret_id       = "vault_secret_id_env"
  }
}*/
provider "kubernetes" {
  //config_path = data.external.kubeconfig.result.filename
  //config_path = "~/.kube/config"
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}
locals {
  worker_groups = [
    {
      # Other parameters omitted for brevity
      bootstrap_extra_args = "--enable-docker-bridge true"
    }
  ]
}
############################################################################### MLNCS Deployment + Service
resource "kubernetes_deployment" "mlncs" {
  metadata {
    name = "mlncs"
    labels = {
      App = "mlncs"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "mlncs"
      }
    }
    template {
      metadata {
        labels = {
          App = "mlncs"
        }
      }
      spec {
        termination_grace_period_seconds = 25
        restart_policy = "Always"
        init_container {
          image = "${var.docker_registry}/mln-python-2:latest"
          name  = "python-2"
          image_pull_policy = "Always"
        }
        init_container {
          image = "${var.docker_registry}/mln-python-3:latest"
          name  = "python-3"
          image_pull_policy = "Always"
        }
        container {
          image = "${var.docker_registry}/mln-cs:latest"
          name  = "mlncs"
          image_pull_policy = "Always"
          port {
            container_port = 3000
          }
          env {
            name = "DOCKER_HOST"
            value = "tcp://localhost:2375"
          }
          env {
            name = "DOCKER_TLS_CERTDIR"
            value = ""
          }
          env {
            name = "DOCKER_DRIVER"
            value = "overlay2"
          }
          volume_mount {
            mount_path = "/app/execute/python/volumes"
            name = "execute"
          }
        }
        container {
          image = "docker:18.09-dind"
          name  = "dind"
          security_context {
            privileged = true
          }
          volume_mount {
            mount_path = "/var/lib/docker"
            name = "dind-storage"
          }
        }
        volume {
          name = "dind-storage"
          empty_dir { }
        }
        volume {
          name = "execute"
          host_path {
            path = "/app/execute/python/volumes"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mlncs" {
  metadata {
    name = "mlncs"
  }
  spec {
    port {
      port = 3000
      target_port = "3000"
      protocol = "TCP"
      name = "mlncs"
    }
    selector = {
      App = "mlncs"
    }
    type = "LoadBalancer"
  }
}

# Create a local variable for the load balancer name.
locals {
  lb_name = split("-", split(".", kubernetes_service.mlncs.status.0.load_balancer.0.ingress.0.hostname).0).0
}

# Read information about the load balancer using the AWS provider.
data "aws_elb" "mlncs" {
  name = local.lb_name
}
############################################################################### MLNUI Deployment + Service
resource "kubernetes_deployment" "mlnui" {
  metadata {
    name = "mlnui"
    labels = {
      App = "mlnui"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "mlnui"
      }
    }
    template {
      metadata {
        labels = {
          App = "mlnui"
        }
      }
      spec {
        container {
          image = "${var.docker_registry}/mln-ui:latest"
          name  = "mlnui"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mlnui" {
  metadata {
    name = "mlnui"
  }
  spec {
    port {
      port = 8080
      target_port = "8080"
      name = "http"
    }
    selector = {
      App = "mlnui"
    }
    type = "LoadBalancer"
  }
}

# Create a local variable for the load balancer name.
locals {
  lb_name_mlnui = split("-", split(".", kubernetes_service.mlnui.status.0.load_balancer.0.ingress.0.hostname).0).0
}

# Read information about the load balancer using the AWS provider.
data "aws_elb" "mlnui" {
  name = local.lb_name_mlnui
}
############################################################################### MLN Redis Deployment + Service
resource "kubernetes_deployment" "mln-redis" {
  metadata {
    name = "mln-redis"
    labels = {
      App = "mln-redis"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        App = "mln-redis"
      }
    }
    template {
      metadata {
        labels = {
          App = "mln-redis"
        }
      }
      spec {
        container {
          image = "redis:alpine"
          name  = "mln-redis"
          image_pull_policy = "Always"
          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mln-redis" {
  metadata {
    name = "mln-redis"
  }
  spec {
    selector = {
      App = "mln-redis"
    }
    port {
      port = 6379
      target_port = 6379
    }
  }
}
############################################################################### user1 account+role bind
resource "kubernetes_service_account" "user1" {
  metadata {
    name = "user1"
    namespace = "default"
  }
  secret {
    name = "${kubernetes_secret.user1.metadata.0.name}"
  }
}
resource "kubernetes_secret" "user1" {
  metadata {
    name = "user1"
  }
}


resource "kubernetes_cluster_role_binding" "user1" {
  metadata {
    name = "user1"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "user1"
    namespace = "default"
  }
}
