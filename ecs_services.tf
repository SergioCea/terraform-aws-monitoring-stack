# Proveedores de capacidad para el cluster (Solo Fargate)
resource "aws_ecs_cluster_capacity_providers" "monitoring_capacity_providers" {
  cluster_name = aws_ecs_cluster.monitoring_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ECS Service para Grafana
resource "aws_ecs_service" "grafana_service" {
  name            = "grafana-service"
  cluster         = aws_ecs_cluster.monitoring_cluster.id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_grafana.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.listener_grafana]

  tags = merge(local.common_tags, { Name = "grafana-service" })
}

# ECS Service para Loki
resource "aws_ecs_service" "loki_service" {
  name            = "loki-service"
  cluster         = aws_ecs_cluster.monitoring_cluster.id
  task_definition = aws_ecs_task_definition.loki_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_loki.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.loki_discovery.arn
  }

  tags = merge(local.common_tags, { Name = "loki-service" })
}

# ECS Service para Prometheus
resource "aws_ecs_service" "prometheus_service" {
  name            = "prometheus-service"
  cluster         = aws_ecs_cluster.monitoring_cluster.id
  task_definition = aws_ecs_task_definition.prometheus_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_prometheus.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus_discovery.arn
  }

  tags = merge(local.common_tags, { Name = "prometheus-service" })
}
