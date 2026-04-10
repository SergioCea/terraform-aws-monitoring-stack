# Application Load Balancer (ALB) para Grafana
resource "aws_lb" "alb_grafana" {
  name               = "alb-grafana"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_grafana_ecs.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = merge(local.common_tags, { Name = "alb-grafana" })
}

# Target Group para Grafana (ECS Service)
resource "aws_lb_target_group" "tg_grafana" {
  name        = "tg-grafana"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    port                = "3000"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(local.common_tags, { Name = "tg-grafana" })
}

# Listener del ALB (Puerto 80)
resource "aws_lb_listener" "listener_grafana" {
  load_balancer_arn = aws_lb.alb_grafana.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_grafana.arn
  }

  tags = local.common_tags
}
