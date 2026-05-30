terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC default
data "aws_vpc" "default" {
  default = true
}

# Subnets da VPC default apenas nas zonas A e B
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["${var.aws_region}a", "${var.aws_region}b"]
  }
}

# Security group existente do banco de dados
data "aws_security_group" "bia_db" {
  name = "bia-rds"
}

# Certificado ACM existente para o dominio (wildcard)
data "aws_acm_certificate" "fmp" {
  domain      = "*.${var.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}

# Zona hospedada existente no Route 53
data "aws_route53_zone" "fmp" {
  name = var.domain_name
}

# AMI ECS-optimized Amazon Linux 2023
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

locals {
  cluster_name = "cluster-bia-alb"
  service_name = "service-bia-alb"
  task_name    = "task-def-bia-alb"
  full_domain  = "${var.subdomain}.${var.domain_name}"
}
