provider "aws" {
  region = "us-west-2"
}

# Variables
variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  default     = "changeme"  # This should be overridden in a secure way
  sensitive   = true
}

# Create a VPC for the RDS instance
resource "aws_vpc" "uat_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "uat-vpc"
  }
}

# Create subnets in different availability zones
resource "aws_subnet" "uat_subnet_1" {
  vpc_id            = aws_vpc.uat_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  
  tags = {
    Name = "uat-subnet-1"
  }
}

resource "aws_subnet" "uat_subnet_2" {
  vpc_id            = aws_vpc.uat_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  
  tags = {
    Name = "uat-subnet-2"
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "uat_db_subnet_group" {
  name       = "uat-db-subnet-group"
  subnet_ids = [aws_subnet.uat_subnet_1.id, aws_subnet.uat_subnet_2.id]
  
  tags = {
    Name = "uat-db-subnet-group"
  }
}

# Create a security group for RDS
resource "aws_security_group" "uat_db_sg" {
  name        = "uat-db-sg"
  description = "Allow inbound traffic to RDS"
  vpc_id      = aws_vpc.uat_vpc.id
  
  ingress {
    description = "MySQL from anywhere"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict this to specific IPs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "uat-db-sg"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "uat_igw" {
  vpc_id = aws_vpc.uat_vpc.id
  
  tags = {
    Name = "uat-igw"
  }
}

# Create a route table
resource "aws_route_table" "uat_route_table" {
  vpc_id = aws_vpc.uat_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.uat_igw.id
  }
  
  tags = {
    Name = "uat-route-table"
  }
}

# Associate route table with subnets
resource "aws_route_table_association" "uat_rta_1" {
  subnet_id      = aws_subnet.uat_subnet_1.id
  route_table_id = aws_route_table.uat_route_table.id
}

resource "aws_route_table_association" "uat_rta_2" {
  subnet_id      = aws_subnet.uat_subnet_2.id
  route_table_id = aws_route_table.uat_route_table.id
}

# Create the RDS instance
resource "aws_db_instance" "uat_notes_db" {
  identifier             = "uat-notes-db"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "notes_app_uat"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.uat_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.uat_db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true  # For easy access from EC2 instances
  
  tags = {
    Name        = "uat-notes-db"
    Environment = "uat"
  }
}

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "uat/notes_app_uat/credentials"
  description = "RDS database credentials for UAT notes app"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "mysql"
    host     = aws_db_instance.uat_notes_db.address
    port     = aws_db_instance.uat_notes_db.port
    dbname   = "notes_app_uat"
  })
}

# Output the RDS endpoint
output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.uat_notes_db.endpoint
}

output "secret_arn" {
  description = "The ARN of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}