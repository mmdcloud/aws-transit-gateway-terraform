terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "bucket_prefix" {
  type        = string
  default     = "terraform-state-tgw-hub"
  description = "Prefix for the remote state S3 bucket name"
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${var.region}"
}

# ----------------------------------------------------------------------
# S3 Bucket for Terraform Remote State
# ----------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = false

  tags = {
    Name        = "Terraform Remote State"
    Environment = "Core-Infrastructure"
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_access_block" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------------------------------------
# DynamoDB Table for Distributed State Locking
# ----------------------------------------------------------------------
resource "aws_dynamodb_table" "locks" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "Core-Infrastructure"
  }
}

