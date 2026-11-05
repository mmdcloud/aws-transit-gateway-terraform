variable "region" {
  type    = string
  default = "ap-south-1"
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
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

# ----------------------------------------------------------------------
# Point 1: Dedicated /28 Subnets for Transit Gateway Attachments
# ----------------------------------------------------------------------
variable "vpc1_tgw_subnets" {
  type        = list(string)
  description = "Dedicated /28 subnets for VPC1 Transit Gateway attachment"
  default     = ["10.1.254.0/28", "10.1.254.16/28", "10.1.254.32/28"]
}

variable "vpc2_tgw_subnets" {
  type        = list(string)
  description = "Dedicated /28 subnets for VPC2 Transit Gateway attachment"
  default     = ["10.2.254.0/28", "10.2.254.16/28", "10.2.254.32/28"]
}

variable "vpc3_tgw_subnets" {
  type        = list(string)
  description = "Dedicated /28 subnets for VPC3 Transit Gateway attachment"
  default     = ["10.3.254.0/28", "10.3.254.16/28", "10.3.254.32/28"]
}

variable "egress_public_subnets" {
  type        = list(string)
  description = "Public subnets for Egress VPC hosting Multi-AZ NAT Gateways"
  default     = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
}

variable "egress_tgw_subnets" {
  type        = list(string)
  description = "Dedicated /28 subnets for Egress VPC Transit Gateway attachment"
  default     = ["10.100.254.0/28", "10.100.254.16/28", "10.100.254.32/28"]
}

# ----------------------------------------------------------------------
# Central Inspection VPC & Suricata NVA Appliance
# ----------------------------------------------------------------------
variable "inspection_appliance_subnets" {
  type        = list(string)
  description = "Appliance subnets in Inspection VPC hosting Suricata NVA ENIs"
  default     = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
}

variable "inspection_tgw_subnets" {
  type        = list(string)
  description = "Dedicated /28 subnets for Inspection VPC Transit Gateway attachment"
  default     = ["10.200.254.0/28", "10.200.254.16/28", "10.200.254.32/28"]
}

variable "nva_instance_type" {
  type        = string
  description = "EC2 Instance type for Suricata NVA appliance"
  default     = "t3.small"
}

# ----------------------------------------------------------------------
# Point 4: AWS RAM Principals for Multi-Account TGW Sharing
# ----------------------------------------------------------------------
variable "ram_principals" {
  type        = list(string)
  description = "List of AWS Organization ARNs, OU ARNs, or Account IDs to share the Transit Gateway with via RAM"
  default     = []
}
