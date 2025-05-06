provider "aws" {
  region = var.region
}

locals {
  # Create a sanitized name by replacing underscores with hyphens
  sanitized_db_name = replace(var.db_name, "_", "-")
  
  # Create a unique identifier for resources
  resource_id = "${var.environment}-${local.sanitized_db_name}"
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.resource_id}-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.environment}-${var.db_name}-subnet-group"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.resource_id}-sg"
  description = "Allow inbound traffic to RDS from EKS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL/Aurora traffic from EKS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.db_name}-sg"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_db_parameter_group" "this" {
  name   = "${local.resource_id}-pg"
  family = var.db_parameter_group_family

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  tags = {
    Name        = "${var.environment}-${var.db_name}-pg"
    Environment = var.environment
    Terraform   = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.environment}/${var.db_name}/credentials"
  description = "RDS database credentials"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = var.db_engine
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}

resource "aws_db_instance" "this" {
  identifier             = local.resource_id
  allocated_storage      = var.db_allocated_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.this.name
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  multi_az               = var.environment == "prod" ? true : false
  storage_encrypted      = true

  tags = {
    Name        = "${var.environment}-${var.db_name}"
    Environment = var.environment
    Terraform   = "true"
  }
}