variable "aws_region" {
  description = "Regiao AWS"
  type        = string
  default     = "us-east-1"
}

variable "ecr_registry" {
  description = "URI do ECR registry"
  type        = string
  default     = "632813643661.dkr.ecr.us-east-1.amazonaws.com"
}

variable "ecr_image" {
  description = "Nome da imagem no ECR"
  type        = string
  default     = "bia"
}

variable "image_tag" {
  description = "Tag da imagem Docker"
  type        = string
  default     = "latest"
}

variable "db_host" {
  description = "Endpoint do RDS"
  type        = string
  default     = "bia-db.c8rkqog0kvxw.us-east-1.rds.amazonaws.com"
}

variable "db_user" {
  description = "Usuario do banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Porta do banco de dados"
  type        = string
  default     = "5432"
}

variable "domain_name" {
  description = "Dominio principal (zona hospedada)"
  type        = string
  default     = "fmp.eti.br"
}

variable "subdomain" {
  description = "Subdominio para a aplicacao"
  type        = string
  default     = "bia"
}

variable "instance_type" {
  description = "Tipo da instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Numero de instancias EC2 no cluster"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Porta do container"
  type        = number
  default     = 8080
}
