output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "ecs_service_name" {
  value = aws_ecs_service.strapi_service.name
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.strapi_db.endpoint
}
