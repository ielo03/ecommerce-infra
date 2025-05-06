provider "aws" {
  region = var.region
}

# Remote state configuration
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state-ielo03"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "ecommerce-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  environment = "prod"
  cluster_name = "ecommerce-eks-${local.environment}"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_name            = "ecommerce-vpc-${local.environment}"
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
  single_nat_gateway  = false  # Use multiple NAT gateways for production for high availability
  cluster_name        = local.cluster_name
  environment         = local.environment
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name         = local.cluster_name
  kubernetes_version   = var.kubernetes_version
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnets
  node_group_min_size  = var.node_group_min_size
  node_group_max_size  = var.node_group_max_size
  node_group_desired_size = var.node_group_desired_size
  node_group_instance_types = var.node_group_instance_types
  environment          = local.environment
}

# ECR Repositories
module "ecr" {
  source = "../../modules/ecr"

  repository_names = [
    "product-service",
    "order-service",
    "user-service",
    "api-gateway"
  ]
  environment = local.environment
}

# RDS Database for Product Service
module "product_db" {
  source = "../../modules/rds"

  environment            = local.environment
  db_name                = "ecommerce_products"
  db_username            = var.db_username
  db_password            = var.db_password
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_engine              = "mysql"
  db_engine_version      = "8.0"
  db_parameter_group_family = "mysql8.0"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  allowed_security_groups = [module.eks.node_security_group_id]
}

# RDS Database for Order Service
module "order_db" {
  source = "../../modules/rds"

  environment            = local.environment
  db_name                = "ecommerce_orders"
  db_username            = var.db_username
  db_password            = var.db_password
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_engine              = "mysql"
  db_engine_version      = "8.0"
  db_parameter_group_family = "mysql8.0"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  allowed_security_groups = [module.eks.node_security_group_id]
}

# RDS Database for User Service
module "user_db" {
  source = "../../modules/rds"

  environment            = local.environment
  db_name                = "ecommerce_users"
  db_username            = var.db_username
  db_password            = var.db_password
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_engine              = "mysql"
  db_engine_version      = "8.0"
  db_parameter_group_family = "mysql8.0"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  allowed_security_groups = [module.eks.node_security_group_id]
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "eks_cluster_id" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "The URLs of the ECR repositories"
  value       = module.ecr.repository_urls
}

output "product_db_endpoint" {
  description = "The endpoint of the product database"
  value       = module.product_db.db_endpoint
}

output "order_db_endpoint" {
  description = "The endpoint of the order database"
  value       = module.order_db.db_endpoint
}

output "user_db_endpoint" {
  description = "The endpoint of the user database"
  value       = module.user_db.db_endpoint
}