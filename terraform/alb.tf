# =============================================
# Application Load Balancer
# =============================================

resource "aws_lb" "bia" {
  name               = "alb-bia"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.bia_alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "alb-bia"
  }
}

# =============================================
# Target Group
# =============================================

resource "aws_lb_target_group" "bia" {
  name     = "tg-bia-alb"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/api/versao"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "tg-bia-alb"
  }
}

# =============================================
# Listener HTTPS (porta 443)
# =============================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.bia.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.fmp.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bia.arn
  }
}

# =============================================
# Listener HTTP (redireciona para HTTPS)
# =============================================

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.bia.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# =============================================
# Route 53 - DNS Record
# =============================================

resource "aws_route53_record" "bia" {
  zone_id = data.aws_route53_zone.fmp.zone_id
  name    = local.full_domain
  type    = "A"

  alias {
    name                   = aws_lb.bia.dns_name
    zone_id                = aws_lb.bia.zone_id
    evaluate_target_health = true
  }
}
