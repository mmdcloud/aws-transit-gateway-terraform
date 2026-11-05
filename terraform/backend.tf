# ----------------------------------------------------------------------
# Point 5: Production Remote Backend (S3 + DynamoDB State Locking)
# ----------------------------------------------------------------------
# In production, team environments require remote state in S3 with
# DynamoDB distributed locking to avoid concurrent state corruption.
#
# Steps to activate:
# 1. cd bootstrap && terraform init && terraform apply
# 2. Uncomment the backend "s3" block below with your bucket name
# 3. cd ../ && terraform init -migrate-state
# ----------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-tgw-hub-344626620590-ap-south-1"
#     key            = "networking/tgw-hub/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "terraform-lock-table"
#     encrypt        = true
#   }
# }

