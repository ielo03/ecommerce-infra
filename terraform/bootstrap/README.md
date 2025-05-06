# Terraform State Backend Setup

This directory contains Terraform configuration to set up the backend infrastructure for storing Terraform state remotely. It creates:

1. An S3 bucket for storing Terraform state files
2. A DynamoDB table for state locking

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Apply the configuration:

```bash
terraform apply
```

3. After applying, note the outputs:

   - `s3_bucket_name`: The name of the S3 bucket for Terraform state
   - `dynamodb_table_name`: The name of the DynamoDB table for Terraform state locking

4. Use these values in the backend configuration of other Terraform configurations:

```hcl
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state-ielo03"
    key            = "env/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "ecommerce-terraform-locks"
    encrypt        = true
  }
}
```

## Important Notes

- The S3 bucket has versioning enabled to keep a history of state files
- The S3 bucket has server-side encryption enabled for security
- The S3 bucket has public access blocked
- The DynamoDB table uses on-demand capacity mode to minimize costs
- The resources have `prevent_destroy` lifecycle configuration to prevent accidental deletion
