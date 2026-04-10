# ECS Cluster para monitorizacion (Prometheus, Grafana, Loki)
resource "aws_ecs_cluster" "monitoring_cluster" {
  name = "monitoring-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(local.common_tags, { Name = "monitoring-cluster" })
}

# Grupos de Logs en CloudWatch
resource "aws_cloudwatch_log_group" "grafana_log_group" {
  name              = "/ecs/grafana-task"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "loki_log_group" {
  name              = "/ecs/loki-task"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "prometheus_log_group" {
  name              = "/ecs/prometheus-task"
  retention_in_days = 7
  tags              = local.common_tags
}

# ECS Task Definition para Grafana
resource "aws_ecs_task_definition" "grafana_task" {
  family                   = "grafana-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "grafana/grafana:latest"
      essential = true
      portMappings = [
        {
          name          = "grafana-3000-tcp"
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      environment = [
        { name = "GF_DATABASE_HOST", value = aws_db_instance.grafana_db.endpoint },
        { name = "GF_DATABASE_TYPE", value = "postgres" },
        { name = "GF_DATABASE_NAME", value = aws_db_instance.grafana_db.db_name },
        { name = "GF_DATABASE_USER", value = aws_db_instance.grafana_db.username },
        { name = "GF_DATABASE_SSL_MODE", value = "require" },
        { name = "GF_DATABASE_MAX_OPEN_CONN", value = "100" },
        { name = "GF_DATABASE_MAX_IDLE_CONN", value = "50" },
        { name = "GF_DATABASE_CONN_MAX_LIFETIME", value = "14400" },
        { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
        { name = "GF_USERS_ALLOW_SIGN_UP", value = "false" },
        { name = "GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS", value = "" },
        { name = "GF_PLUGINS_PLUGIN_ADMIN_ENABLED", value = "false" },
        { name = "GF_PLUGINS_ENABLE_ALPHA", value = "false" },
        { name = "GF_FEATURE_TOGGLES_ENABLE", value = "" }
      ]
      secrets = [
        {
          name      = "GF_DATABASE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        },
        {
          name      = "GF_SECURITY_ADMIN_PASSWORD"
          valueFrom = aws_secretsmanager_secret.grafana_admin_password.arn
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "grafana_data"
          containerPath = "/var/lib/grafana"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  volume {
    name = "grafana_data"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.app_efs.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = aws_efs_access_point.grafana_data.id
        iam             = "DISABLED"
      }
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = local.common_tags
}

# ECS Task Definition para Loki
resource "aws_ecs_task_definition" "loki_task" {
  family                   = "loki-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "init-config"
      image     = "amazon/aws-cli:latest"
      essential = false
      entryPoint = ["/bin/bash", "-c"]
      command   = ["aws s3 cp s3://${aws_s3_bucket.monitorizacion_bucket.id}/loki-config.yaml /etc/loki/loki-config.yaml && chown -R 10001:10001 /loki"]
      mountPoints = [
        {
          sourceVolume  = "loki_config"
          containerPath = "/etc/loki"
          readOnly      = false
        },
        {
          sourceVolume  = "loki_data"
          containerPath = "/loki"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.loki_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs-init"
          "awslogs-create-group"  = "true"
        }
      }
    },
    {
      name      = "loki"
      image     = "grafana/loki:latest"
      essential = true
      command   = ["-config.file=/etc/loki/loki-config.yaml", "-config.expand-env=true"]
      portMappings = [
        {
          name          = "loki-3100-tcp"
          containerPort = 3100
          hostPort      = 3100
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      dependsOn = [
        {
          containerName = "init-config"
          condition     = "SUCCESS"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "loki_data"
          containerPath = "/loki"
          readOnly      = false
        },
        {
          sourceVolume  = "loki_config"
          containerPath = "/etc/loki"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.loki_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  volume {
    name = "loki_data"
  }

  volume {
    name = "loki_config"
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = local.common_tags
}

# ECS Task Definition para Prometheus
resource "aws_ecs_task_definition" "prometheus_task" {
  family                   = "prometheus-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "init-config"
      image     = "amazon/aws-cli:latest"
      essential = false
      entryPoint = ["/bin/bash", "-c"]
      command   = ["aws s3 cp s3://${aws_s3_bucket.monitorizacion_bucket.id}/prometheus/ /etc/prometheus/ --recursive && chown -R 65534:65534 /prometheus"]
      mountPoints = [
        {
          sourceVolume  = "prometheus_config"
          containerPath = "/etc/prometheus"
          readOnly      = false
        },
        {
          sourceVolume  = "prometheus_data"
          containerPath = "/prometheus"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prometheus_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs-init"
          "awslogs-create-group"  = "true"
        }
      }
    },
    {
      name      = "prometheus"
      image     = "prom/prometheus:latest"
      essential = true
      command   = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--web.console.libraries=/etc/prometheus/console_libraries",
        "--web.console.templates=/etc/prometheus/consoles",
        "--storage.tsdb.retention.time=24h",
        "--web.enable-lifecycle",
        "--web.enable-remote-write-receiver"
      ]
      portMappings = [
        {
          name          = "prometheus-9090-tcp"
          containerPort = 9090
          hostPort      = 9090
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      dependsOn = [
        {
          containerName = "init-config"
          condition     = "SUCCESS"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "prometheus_data"
          containerPath = "/prometheus"
          readOnly      = false
        },
        {
          sourceVolume  = "prometheus_config"
          containerPath = "/etc/prometheus"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prometheus_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  volume {
    name = "prometheus_data"
  }

  volume {
    name = "prometheus_config"
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = local.common_tags
}
