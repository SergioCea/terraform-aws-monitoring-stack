# Grupos de Seguridad
resource "aws_security_group" "efs_app" {
  name        = "efs-app"
  description = "Security group for EFS App"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "efs-app" })
}

resource "aws_security_group" "ecs_prometheus" {
  name        = "ecs-prometheus"
  description = "Security group for ECS Prometheus"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "ecs-prometheus" })
}

resource "aws_security_group" "alb_grafana_ecs" {
  name        = "alb-grafana-ecs"
  description = "Security group for ALB Grafana ECS"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "alb-grafana-ecs" })
}

resource "aws_security_group" "rds_app" {
  name        = "rds-app"
  description = "Security group for RDS App"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "rds-app" })
}

resource "aws_security_group" "ec2_app" {
  name        = "ec2-app"
  description = "Security group for EC2 App"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "ec2-app" })
}

resource "aws_security_group" "ecs_grafana" {
  name        = "ecs-grafana"
  description = "Security group for ECS Grafana"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "ecs-grafana" })
}

resource "aws_security_group" "ecs_loki" {
  name        = "ecs-loki"
  description = "Security group for ECS Loki"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(local.common_tags, { Name = "ecs-loki" })
}

# Reglas de Ingress
# efs-app
resource "aws_security_group_rule" "efs_app_ingress_ec2_app" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Permitir trafico NFS desde EC2 App"
  security_group_id        = aws_security_group.efs_app.id
  source_security_group_id = aws_security_group.ec2_app.id
}

resource "aws_security_group_rule" "efs_app_ingress_ecs_grafana" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Permitir trafico NFS desde ECS Grafana"
  security_group_id        = aws_security_group.efs_app.id
  source_security_group_id = aws_security_group.ecs_grafana.id
}

resource "aws_security_group_rule" "efs_app_ingress_ecs_loki" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Permitir trafico NFS desde ECS Loki"
  security_group_id        = aws_security_group.efs_app.id
  source_security_group_id = aws_security_group.ecs_loki.id
}

resource "aws_security_group_rule" "efs_app_ingress_ecs_prometheus" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Permitir trafico NFS desde ECS Prometheus"
  security_group_id        = aws_security_group.efs_app.id
  source_security_group_id = aws_security_group.ecs_prometheus.id
}

# ecs-prometheus
resource "aws_security_group_rule" "ecs_prometheus_ingress_ecs_grafana" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  description              = "Permitir acceso a Prometheus desde Grafana"
  security_group_id        = aws_security_group.ecs_prometheus.id
  source_security_group_id = aws_security_group.ecs_grafana.id
}

resource "aws_security_group_rule" "ecs_prometheus_ingress_ec2_app" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  description              = "Permitir acceso a Prometheus desde EC2 App"
  security_group_id        = aws_security_group.ecs_prometheus.id
  source_security_group_id = aws_security_group.ec2_app.id
}

resource "aws_security_group_rule" "ecs_prometheus_ingress_ecs_loki" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  description              = "Permitir acceso a Prometheus desde Loki"
  security_group_id        = aws_security_group.ecs_prometheus.id
  source_security_group_id = aws_security_group.ecs_loki.id
}

# alb-grafana-ecs
resource "aws_security_group_rule" "alb_grafana_ecs_ingress_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Permite el acceso a la UI de Grafana"
  security_group_id = aws_security_group.alb_grafana_ecs.id
}

# rds-app
resource "aws_security_group_rule" "rds_app_ingress_ecs_grafana" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  description              = "Permite la conexion a la BD"
  security_group_id        = aws_security_group.rds_app.id
  source_security_group_id = aws_security_group.ecs_grafana.id
}

# ec2-app
resource "aws_security_group_rule" "ec2_app_ingress_22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Permitir acceso SSH"
  security_group_id = aws_security_group.ec2_app.id
}

resource "aws_security_group_rule" "ec2_app_ingress_8000" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Puerto expuesto por la APP"
  security_group_id = aws_security_group.ec2_app.id
}

# ecs-grafana
resource "aws_security_group_rule" "ecs_grafana_ingress_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  description              = "Permitir conexion ALB"
  security_group_id        = aws_security_group.ecs_grafana.id
  source_security_group_id = aws_security_group.alb_grafana_ecs.id
}

# ecs-loki
resource "aws_security_group_rule" "ecs_loki_ingress_ecs_grafana" {
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  description              = "Permitir trafico de Loki desde Grafana"
  security_group_id        = aws_security_group.ecs_loki.id
  source_security_group_id = aws_security_group.ecs_grafana.id
}

resource "aws_security_group_rule" "ecs_loki_ingress_ec2_app" {
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  description              = "Permitir trafico de Loki desde EC2 App"
  security_group_id        = aws_security_group.ecs_loki.id
  source_security_group_id = aws_security_group.ec2_app.id
}

resource "aws_security_group_rule" "ecs_loki_ingress_ecs_prometheus" {
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  description              = "Permitir scraping de Loki desde Prometheus"
  security_group_id        = aws_security_group.ecs_loki.id
  source_security_group_id = aws_security_group.ecs_prometheus.id
}

# Reglas de Egress
# Regla general de salida para todos los grupos
resource "aws_security_group_rule" "efs_app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para EFS"
  security_group_id = aws_security_group.efs_app.id
}

resource "aws_security_group_rule" "ecs_prometheus_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para Prometheus"
  security_group_id = aws_security_group.ecs_prometheus.id
}

resource "aws_security_group_rule" "alb_grafana_ecs_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para ALB"
  security_group_id = aws_security_group.alb_grafana_ecs.id
}

resource "aws_security_group_rule" "rds_app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para RDS"
  security_group_id = aws_security_group.rds_app.id
}

resource "aws_security_group_rule" "ec2_app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para EC2 App"
  security_group_id = aws_security_group.ec2_app.id
}

resource "aws_security_group_rule" "ecs_grafana_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para Grafana"
  security_group_id = aws_security_group.ecs_grafana.id
}

resource "aws_security_group_rule" "ecs_loki_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Salida total de trafico para Loki"
  security_group_id = aws_security_group.ecs_loki.id
}

# Reglas de Egress especificas a otros SGs
resource "aws_security_group_rule" "ecs_prometheus_egress_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Enviar trafico al EFS"
  security_group_id        = aws_security_group.ecs_prometheus.id
  source_security_group_id = aws_security_group.efs_app.id
}

resource "aws_security_group_rule" "ec2_app_egress_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Enviar trafico al EFS"
  security_group_id        = aws_security_group.ec2_app.id
  source_security_group_id = aws_security_group.efs_app.id
}

resource "aws_security_group_rule" "ecs_grafana_egress_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Enviar trafico al EFS"
  security_group_id        = aws_security_group.ecs_grafana.id
  source_security_group_id = aws_security_group.efs_app.id
}

resource "aws_security_group_rule" "ecs_loki_egress_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "Enviar trafico al EFS"
  security_group_id        = aws_security_group.ecs_loki.id
  source_security_group_id = aws_security_group.efs_app.id
}
