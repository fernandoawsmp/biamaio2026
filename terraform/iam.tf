# =============================================
# IAM Role para as instancias EC2 do ECS
# =============================================

resource "aws_iam_role" "ecs_instance_role" {
  name = "role-ecs-bia-alb"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "role-ecs-bia-alb"
  }
}

# Permite que a instancia EC2 se registre no cluster ECS
resource "aws_iam_role_policy_attachment" "ecs_instance_ec2" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Permite acesso via SSM (Session Manager)
resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile (necessario para associar a role a uma EC2)
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "role-ecs-bia-alb"
  role = aws_iam_role.ecs_instance_role.name
}

# =============================================
# IAM Role para execucao de tasks do ECS
# =============================================

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "role-ecs-task-exec-bia"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "role-ecs-task-exec-bia"
  }
}

# Permite ao agente ECS puxar imagens do ECR e escrever logs
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
