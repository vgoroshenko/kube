output "load_balancer_name_mlnui" {
  value = local.lb_name_mlnui
}

output "load_balancer_hostname_mlnui" {
  value = kubernetes_service.mlnui.status.0.load_balancer.0.ingress.0.hostname
}

output "load_balancer_info_mlnui" {
  value = data.aws_elb.mlncs
}

output "load_balancer_name_mlncs" {
  value = local.lb_name
}

output "load_balancer_hostname_mlncs" {
  value = kubernetes_service.mlncs.status.0.load_balancer.0.ingress.0.hostname
}

output "load_balancer_info_mlncs" {
  value = data.aws_elb.mlncs
}

output "load_balancer_name_mlncs_dev" {
  value = local.lb_name_mlncs_dev
}

output "load_balancer_hostname_mlncs_dev" {
  value = kubernetes_service.mlncs-dev.status.0.load_balancer.0.ingress.0.hostname
}

output "load_balancer_info_mlncs_dev" {
  value = data.aws_elb.mlncs-dev
}
