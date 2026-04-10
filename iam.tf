# IAM Role para la ejecucion de tareas de ECS (Task Execution Role)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-Monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
}

# Adjuntar la politica estandar de ejecucion de tareas de ECS
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Politica para permitir lectura de S3 y Secrets Manager (para el Execution Role)
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecs-task-execution-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          aws_s3_object.loki_config.arn,
          "${aws_s3_bucket.monitorizacion_bucket.arn}/prometheus/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation"]
        Resource = [aws_s3_bucket.monitorizacion_bucket.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.grafana_admin_password.arn
        ]
      }
    ]
  })
}

# IAM Role para la Tarea de ECS (Task Role) para que los contenedores usen AWS CLI
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole-Monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
}

# Politica para que el Task Role lea y escriba en S3 (usado por Init Container y Loki)
resource "aws_iam_role_policy" "ecs_task_role_s3_policy" {
  name = "ecs-task-role-s3-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.monitorizacion_bucket.arn,
          "${aws_s3_bucket.monitorizacion_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = [aws_s3_bucket.monitorizacion_bucket.arn]
      }
    ]
  })
}
