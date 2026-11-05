output "s3_bucket_name" {
  description = "The S3 bucket name created for remote state storage"
  value       = aws_s3_bucket.state.id
}

output "dynamodb_table_name" {
  description = "The DynamoDB table name created for state locking"
  value       = aws_dynamodb_table.locks.name
}

output "backend_config_snippet" {
  description = "Copy this configuration snippet into your backend.tf"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state.id}"
        key            = "networking/tgw-hub/terraform.tfstate"
        region         = "${var.region}"
        dynamodb_table = "${aws_dynamodb_table.locks.name}"
        encrypt        = true
      }
    }
  EOT
}

