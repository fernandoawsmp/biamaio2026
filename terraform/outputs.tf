output "alb_dns_name" {
  description = "DNS name do ALB"
  value       = aws_lb.bia.dns_name
}

output "app_url" {
  description = "URL da aplicacao"
  value       = "https://${local.full_domain}"
}

output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.bia_alb.name
}

output "service_name" {
  description = "Nome do servico ECS"
  value       = aws_ecs_service.bia_alb.name
}
