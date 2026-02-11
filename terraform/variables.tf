variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc1_private_subnets" {
  type    = list(string)
  default = []
}

variable "vpc1_public_subnets" {
  type    = list(string)
  default = []
}

variable "vpc2_private_subnets" {
  type    = list(string)
  default = []
}

variable "vpc2_public_subnets" {
  type    = list(string)
  default = []
}

variable "vpc3_private_subnets" {
  type    = list(string)
  default = []
}

variable "vpc3_public_subnets" {
  type    = list(string)
  default = []
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
