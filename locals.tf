locals {
  common_tags = {
    Project     = var.project_name
    Owner       = "DevOps-Team"
    ManagedBy   = "Terraform"
    Environment = "Test"
  }
}
