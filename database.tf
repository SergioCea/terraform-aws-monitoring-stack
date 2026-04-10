# Subnet Group para la base de datos RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = merge(local.common_tags, { Name = "RDS Subnet Group" })
}

# Instancia de Base de Datos RDS (PostgreSQL) para Grafana
resource "aws_db_instance" "grafana_db" {
  identifier           = "grafana-db"
  engine               = "postgres"
  engine_version       = "17.6"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  db_name              = "grafana"
  username             = "grafana"
  password             = var.db_password
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.rds_app.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = merge(local.common_tags, { Name = "Grafana DB" })
}

# Mejora 2: AWS Secrets Manager para las contrasenas
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "grafana-db-password"
  description             = "Contrasena de la base de datos Grafana"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "grafana_admin_password" {
  name                    = "grafana-admin-password"
  description             = "Contrasena de administrador de Grafana"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "grafana_admin_password" {
  secret_id     = aws_secretsmanager_secret.grafana_admin_password.id
  secret_string = var.grafana_admin_password
}
