variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., qa, uat, prod)"
  type        = string
}