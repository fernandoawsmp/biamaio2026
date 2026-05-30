# =============================================
# Security Group para o ALB
# =============================================

resource "aws_security_group" "bia_alb" {
  name        = "bia-alb"
  description = "Security group do ALB da BIA"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "acesso publico HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "acesso publico HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bia-alb"
  }
}

# =============================================
# Security Group para as instancias EC2 do ECS
# =============================================

resource "aws_security_group" "bia_ec2" {
  name        = "bia-ec2"
  description = "Security group das instancias EC2 do ECS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "acesso vindo de bia-alb"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.bia_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bia-ec2"
  }
}

# =============================================
# Regra adicional no security group do banco (bia-db)
# Permite acesso das instancias EC2 do ECS ao PostgreSQL
# =============================================

resource "aws_security_group_rule" "bia_db_from_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  description              = "acesso vindo de bia-ec2"
  security_group_id        = data.aws_security_group.bia_db.id
  source_security_group_id = aws_security_group.bia_ec2.id
}
