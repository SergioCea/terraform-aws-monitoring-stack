# AWS Monitoring Infrastructure

Infrastructure as Code (IaC) to deploy a complete monitoring stack on AWS using Terraform. This project sets up Grafana, Prometheus, and Loki on Amazon ECS (Fargate), providing a robust observability platform.

## 🚀 Overview

This repository contains the Terraform configuration for deploying a production-ready monitoring ecosystem:
- **Grafana**: Visualization platform for metrics and logs.
- **Prometheus**: Metric collection with local 24h retention and remote write to Amazon Managed Prometheus (AMP).
- **Loki**: Log aggregation system using Amazon S3 for long-term storage.
- **Support Infrastructure**: VPC, Private Subnets, RDS (PostgreSQL) for Grafana backend, ECS Cluster (Fargate), Application Load Balancer (ALB), S3 for configs/logs, and EFS for Grafana persistence.

## 🛠 Tech Stack

- **Infrastructure**: Terraform (>= 1.14.0)
- **Cloud Provider**: AWS (Provider >= 6.17.0)
- **Container Orchestration**: Amazon ECS (Fargate)
- **Monitoring**: Prometheus, Grafana, Loki
- **Database**: Amazon RDS for PostgreSQL (Grafana configuration storage)
- **Storage**: 
    - Amazon S3 (Loki logs & configuration files)
    - Amazon EFS (Grafana `/var/lib/grafana` persistence)
- **Service Discovery**: AWS Cloud Map (for internal communication between Prometheus, Loki, and targets)

## 📋 Prerequisites

Before you begin, ensure you have:
- [Terraform](https://www.terraform.io/downloads.html) >= 1.14.0 installed.
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.
- An AWS account with permissions to manage ECS, RDS, S3, EFS, VPC, IAM, and AMP.
- (Optional) A VPC ID if you want to use an existing one (see `variables.tf`).


## 🔑 Variables & Environment

Key variables defined in `variables.tf`:

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS Region | `eu-south-2` |
| `project_name` | Name of the project | `monitorizacion` |
| `db_password` | RDS Password | (See `variables.tf`) |
| `grafana_admin_password` | Grafana Admin Password | `admin123` |

All resources include `local.common_tags` for consistent ownership and project identification.


## ⚙️ Setup & Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Verify Configuration**:
   ```bash
   terraform validate
   ```

3. **Formatting Check**:
   ```bash
   terraform fmt -check
   ```

4. **Preview Changes**:
   ```bash
   terraform plan
   ```

5. **Apply Infrastructure**:
   ```bash
   terraform apply
   ```

## 📂 Project Structure

```text
.
├── database.tf           # RDS PostgreSQL instance for Grafana persistence
├── ecs_services.tf       # ECS service definitions (Grafana, Prometheus, Loki)
├── ecs_tasks.tf          # ECS task definitions with container configurations
├── iam.tf                # IAM roles and policies for ECS execution and tasks
├── load_balancer.tf      # ALB configuration for external Grafana access
├── locals.tf             # Common tags and project-wide local variables
├── loki/
│   └── loki-config.yaml  # Configuration template for Loki
├── network.tf            # VPC, Subnets, Security Groups, and Cloud Map (Service Discovery)
├── outputs.tf            # Terraform outputs (ALB DNS, RDS endpoint, etc.)
├── prometheus/
│   ├── prometheus.yml    # Prometheus main configuration template
│   └── rules/
│       └── alertas.yml   # Alerting rules for Prometheus
├── providers.tf          # Terraform providers and version requirements
├── security.tf           # Detailed Security Group rules for all components
├── storage.tf            # S3 buckets, EFS, and Amazon Managed Prometheus (AMP)
└── variables.tf          # Input variable definitions and defaults
```

## 📊 Component Details

- **Grafana**:
  - Accessible via the ALB DNS name (see `terraform output`).
  - Backend: RDS PostgreSQL for high availability of dashboards and users.
  - Data Persistence: EFS mounted at `/var/lib/grafana`.
- **Prometheus**:
  - Scrapes metrics from ECS services via AWS Cloud Map.
  - Storage: 24h local ephemeral storage + Remote Write to Amazon Managed Prometheus (AMP) for long-term retention.
  - Configuration: Dynamically loaded from S3 during task startup via an init container.
- **Loki**:
  - Log aggregation using S3 as the storage backend.
  - Configuration: Managed via S3 and template-rendered by Terraform.
- **Networking**:
  - Components are deployed in private subnets for security.
  - Service discovery enabled via AWS Cloud Map (Internal domain for Loki/Prometheus).

## 🧪 Testing

Infrastructure validation is performed using built-in Terraform tools:

- **Syntax Validation**: `terraform validate`
- **Style Enforcement**: `terraform fmt -check`
- **Dry Run/Plan**: `terraform plan`
