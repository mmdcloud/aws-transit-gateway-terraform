variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "intra_subnets" {
  type        = list(string)
  default     = []
  description = "Dedicated subnets with no internet/NAT routes (ideal for TGW attachments)"
}

variable "database_subnets" {
  type    = list(string)
  default = []
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "create_igw" {
  type    = bool
  default = true
}

variable "map_public_ip_on_launch" {
  type    = bool
  default = false
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "one_nat_gateway_per_az" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
