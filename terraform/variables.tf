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
# Inter-Region Transit Gateway Peering (Secondary Region)
# ----------------------------------------------------------------------
variable "peer_region" {
  type        = string
  description = "Secondary AWS region for Inter-Region Transit Gateway Peering"
  default     = "us-west-2"
}

variable "peer_azs" {
  type        = list(string)
  description = "Availability Zones in the Peer Region"
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "primary_tgw_asn" {
  type        = number
  description = "Unique Amazon-side ASN for the Primary Transit Gateway"
  default     = 64512
}

variable "peer_tgw_asn" {
  type        = number
  description = "Unique Amazon-side ASN for the Peer Transit Gateway"
  default     = 64513
}

variable "peer_vpc_cidr" {
  type        = string
  description = "CIDR block for Peer Spoke VPC (VPC 4)"
  default     = "10.4.0.0/16"
}

variable "peer_vpc_public_subnets" {
  type        = list(string)
  description = "Public subnets for Peer Spoke VPC"
  default     = ["10.4.1.0/24", "10.4.2.0/24", "10.4.3.0/24"]
}

variable "peer_vpc_private_subnets" {
  type        = list(string)
  description = "Private workload subnets for Peer Spoke VPC"
  default     = ["10.4.4.0/24", "10.4.5.0/24", "10.4.6.0/24"]
}

variable "peer_vpc_tgw_subnets" {
  type        = list(string)
  description = "Dedicated /28 subnets for Peer Spoke VPC Transit Gateway attachment"
  default     = ["10.4.254.0/28", "10.4.254.16/28", "10.4.254.32/28"]
}

variable "peer_centralized_egress" {
  type        = bool
  description = "Route Peer VPC outbound internet (0.0.0.0/0) across TGW Peering through Primary Suricata NVA & Central Egress NAT"
  default     = true
}

# ----------------------------------------------------------------------
# Point 4: AWS RAM Principals for Multi-Account TGW Sharing
# ----------------------------------------------------------------------
variable "ram_principals" {
  type        = list(string)
  description = "List of AWS Organization ARNs, OU ARNs, or Account IDs to share the Transit Gateway with via RAM"
  default     = []
}
