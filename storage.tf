# Recursos de EFS
resource "aws_efs_file_system" "app_efs" {
  creation_token = "app-efs"
  encrypted      = true

  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(local.common_tags, { Name = "app-efs" })
}

# Puntos de Acceso EFS
resource "aws_efs_access_point" "grafana_data" {
  file_system_id = aws_efs_file_system.app_efs.id

  posix_user {
    gid = 472
    uid = 472
  }

  root_directory {
    path = "/grafana_data"
    creation_info {
      owner_gid   = 472
      owner_uid   = 472
      permissions = "0755"
    }
  }

  tags = merge(local.common_tags, { Name = "Grafana Data" })
}

# Puntos de Montaje EFS (Mount Targets) para cada subnet de la VPC por defecto
resource "aws_efs_mount_target" "app_efs_mt" {
  for_each = toset(data.aws_subnets.default.ids)

  file_system_id  = aws_efs_file_system.app_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_app.id]
}

# Recurso S3 para el archivo de entorno y otros datos
resource "aws_s3_bucket" "monitorizacion_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = merge(local.common_tags, { Name = "Monitoring Storage Bucket" })
}


# Subir el archivo de configuracion de Loki (loki-config.yaml) al bucket de S3
resource "aws_s3_object" "loki_config" {
  bucket = aws_s3_bucket.monitorizacion_bucket.id
  key    = "loki-config.yaml"
  content = templatefile("${path.module}/loki/loki-config.yaml", {
    S3_BUCKET_NAME = aws_s3_bucket.monitorizacion_bucket.id
    AWS_REGION     = var.region
  })

  tags = merge(local.common_tags, { Name = "Loki Configuration File" })
}

# Subir los archivos de configuracion de Prometheus al bucket de S3
resource "aws_s3_object" "prometheus_config" {
  bucket  = aws_s3_bucket.monitorizacion_bucket.id
  key     = "prometheus/prometheus.yml"
  content = templatefile("${path.module}/prometheus/prometheus.yml", {
    alb_dns             = aws_lb.alb_grafana.dns_name
    prometheus_endpoint = aws_prometheus_workspace.monitoring_workspace.prometheus_endpoint
    region              = var.region
  })

  tags = merge(local.common_tags, { Name = "Prometheus Configuration File" })
}

# Amazon Managed Prometheus (AMP) Workspace para almacenamiento a largo plazo
resource "aws_prometheus_workspace" "monitoring_workspace" {
  alias = "monitoring-workspace"

  tags = local.common_tags
}

resource "aws_s3_object" "prometheus_rules" {
  bucket = aws_s3_bucket.monitorizacion_bucket.id
  key    = "prometheus/rules/alertas.yml"
  source = "${path.module}/prometheus/rules/alertas.yml"
  etag   = filemd5("${path.module}/prometheus/rules/alertas.yml")

  tags = merge(local.common_tags, { Name = "Prometheus Rules File" })
}
