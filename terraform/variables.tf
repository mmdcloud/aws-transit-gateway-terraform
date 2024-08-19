variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc1_subnets" {
  type        = list(string)
  description = "VPC1 Subnets"
  default     = ["10.1.0.10/28", "10.1.0.20/28", "10.1.0.100/28"]
}

variable "vpc2_subnets" {
  type        = list(string)
  description = "VPC2 Subnets"
  default     = ["10.2.0.10/28", "10.2.0.20/28", "10.2.0.100/28"]
}

variable "vpc3_subnets" {
  type        = list(string)
  description = "VPC3 Subnets"
  default     = ["10.3.0.10/28", "10.3.0.20/28", "10.3.0.100/28"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
