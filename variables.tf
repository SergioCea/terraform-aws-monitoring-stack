variable "region" {
  type        = string
  description = "Region de AWS"
  default     = "eu-south-2"
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
  default     = "aws-monitoring"
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket de S3 para configuracion"
  default     = "s3-monitoring-storage-897722692980-eu-south-2"
}

variable "db_password" {
  type        = string
  description = "Contrasena para la base de datos RDS"
  default     = "hKileJ485AdV1ABk9b"
  sensitive   = true
}

variable "grafana_admin_password" {
  type        = string
  description = "Contrasena de administrador para Grafana"
  default     = "admin123"
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC por defecto (opcional)"
  default     = ""
}
