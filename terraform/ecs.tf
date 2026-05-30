# =============================================
# ECS Cluster
# =============================================

resource "aws_ecs_cluster" "bia_alb" {
  name = local.cluster_name

  tags = {
    Name = local.cluster_name
  }
}

# =============================================
# Launch Template para as instancias EC2
# =============================================

resource "aws_launch_template" "ecs_instances" {
  name          = "lt-bia-alb"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.bia_ec2.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = local.cluster_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-bia-alb"
    }
  }

  tags = {
    Name = "lt-bia-alb"
  }
}

# =============================================
# Auto Scaling Group (simples - capacidade fixa)
# =============================================

resource "aws_autoscaling_group" "ecs_instances" {
  name                = "asg-bia-alb"
  desired_capacity    = var.instance_count
  min_size            = var.instance_count
  max_size            = var.instance_count
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-bia-alb"
    propagate_at_launch = true
  }
}

# =============================================
# Task Definition
# =============================================

resource "aws_ecs_task_definition" "bia_alb" {
  family             = local.task_name
  network_mode       = "bridge"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name              = "bia"
    image             = "${var.ecr_registry}/${var.ecr_image}:${var.image_tag}"
    cpu               = 1024
    memoryReservation = 40
    essential         = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = 0
      protocol      = "tcp"
    }]

    environment = [
      { name = "DB_HOST", value = var.db_host },
      { name = "DB_USER", value = var.db_user },
      { name = "DB_PWD", value = var.db_password },
      { name = "DB_PORT", value = var.db_port }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.task_name}"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "bia"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = {
    Name = local.task_name
  }
}

# =============================================
# ECS Service
# =============================================

resource "aws_ecs_service" "bia_alb" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.bia_alb.id
  task_definition = aws_ecs_task_definition.bia_alb.arn
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.bia.arn
    container_name   = "bia"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.https]

  tags = {
    Name = local.service_name
  }
}
