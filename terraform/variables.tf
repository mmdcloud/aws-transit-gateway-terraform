variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc1_subnets" {
  type        = list(string)
  description = "VPC1 Subnets"
  default     = ["10.1.0.0/28", "10.1.0.16/28", "10.1.0.96/28"]
}

variable "vpc2_subnets" {
  type        = list(string)
  description = "VPC2 Subnets"
  default     = ["10.2.0.0/28", "10.2.0.16/28", "10.2.0.96/28"]
}

variable "vpc3_subnets" {
  type        = list(string)
  description = "VPC3 Subnets"
  default     = ["10.3.0.0/28", "10.3.0.16/28", "10.3.0.96/28"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "user_data" {
  type    = string
  default = <<EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
  EOF
}
