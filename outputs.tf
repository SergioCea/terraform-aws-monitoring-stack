output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.alb_grafana.dns_name
}

output "rds_endpoint" {
  description = "Endpoint de la base de datos RDS"
  value       = aws_db_instance.grafana_db.endpoint
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.monitoring_cluster.name
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.monitorizacion_bucket.id
}
