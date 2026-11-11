variable "name" {
  type        = string
  description = "Base name prefix for TGW peering resources"
}

variable "primary_transit_gateway_id" {
  type        = string
  description = "Transit Gateway ID in the primary (requester) region"
}

variable "primary_post_inspection_route_table_id" {
  type        = string
  description = "Primary TGW Post-Inspection route table ID (routes inspected traffic to remote peer CIDRs)"
}

variable "primary_inspection_attachment_id" {
  type        = string
  description = "Primary TGW Inspection VPC attachment ID (incoming peered traffic is inspected before spokes)"
}

variable "primary_spoke_cidrs" {
  type        = list(string)
  description = "Primary region Spoke VPC CIDRs reachable across peering"
}

variable "primary_blackhole_cidrs" {
  type        = list(string)
  default     = []
  description = "Infrastructure CIDRs on primary side to block from direct peer access (e.g., Inspection & Egress VPC CIDRs)"
}

variable "peer_region" {
  type        = string
  description = "AWS region of the Peer Transit Gateway"
}

variable "peer_account_id" {
  type        = string
  description = "AWS Account ID owning the Peer Transit Gateway"
}

variable "peer_tgw_asn" {
  type        = number
  default     = 64513
  description = "Unique Amazon-side ASN for the Peer Transit Gateway"
}

variable "peer_spoke_attachments" {
  type = list(object({
    vpc_id     = string
    subnet_ids = list(string)
    name       = optional(string)
  }))
  default     = []
  description = "List of spoke VPC attachments in the Peer region"
}

variable "peer_vpc_cidrs" {
  type        = list(string)
  description = "Peer region Spoke VPC CIDRs reachable across peering"
}

variable "peer_centralized_egress" {
  type        = bool
  default     = true
  description = "Whether Peer region routes 0.0.0.0/0 across TGW peering through Primary Inspection & Central Egress"
}
