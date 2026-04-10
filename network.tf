# Datos de la VPC por defecto y sus subnets
data "aws_vpc" "default" {
  default = var.vpc_id == "" ? true : false
  id      = var.vpc_id == "" ? null : var.vpc_id
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Namespace de CloudMap para Service Discovery
resource "aws_service_discovery_private_dns_namespace" "monitoring_namespace" {
  name        = "monitorizacion"
  description = "Namespace para el cluster de monitorizacion"
  vpc         = data.aws_vpc.default.id
  tags        = local.common_tags
}

# Service Discovery para Loki
resource "aws_service_discovery_service" "loki_discovery" {
  name = "loki"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring_namespace.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "WEIGHTED"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = local.common_tags
}

# Service Discovery para Prometheus
resource "aws_service_discovery_service" "prometheus_discovery" {
  name = "prometheus"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring_namespace.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "WEIGHTED"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = local.common_tags
}
