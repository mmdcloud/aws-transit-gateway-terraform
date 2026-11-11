# ----------------------------------------------------------------------
# Peer Region Transit Gateway (Secondary Region)
# ----------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "peer" {
  provider                        = aws.peer
  description                     = "Peer Region Transit Gateway (${var.peer_region})"
  amazon_side_asn                 = var.peer_tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "${var.name}-${var.peer_region}"
  }
}

# ----------------------------------------------------------------------
# Peer Region Spoke VPC Attachments
# ----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "peer_spokes" {
  count              = length(var.peer_spoke_attachments)
  provider           = aws.peer
  transit_gateway_id = aws_ec2_transit_gateway.peer.id
  vpc_id             = var.peer_spoke_attachments[count.index].vpc_id
  subnet_ids         = var.peer_spoke_attachments[count.index].subnet_ids

  tags = {
    Name = try(var.peer_spoke_attachments[count.index].name != null ? var.peer_spoke_attachments[count.index].name : "${var.name}-peer-spoke-${count.index + 1}", "${var.name}-peer-spoke-${count.index + 1}")
  }
}

# ----------------------------------------------------------------------
# Inter-Region Transit Gateway Peering Attachment & Accepter
# ----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  peer_account_id         = var.peer_account_id
  peer_region             = var.peer_region
  peer_transit_gateway_id = aws_ec2_transit_gateway.peer.id
  transit_gateway_id      = var.primary_transit_gateway_id

  tags = {
    Name = "${var.name}-peering-requester"
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
  provider                      = aws.peer
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this.id

  tags = {
    Name = "${var.name}-peering-accepter"
  }
}

# ----------------------------------------------------------------------
# Primary Region Peering Route Table & Inspection Steering
# ----------------------------------------------------------------------
# Dedicated route table for traffic arriving from Peer Region over TGW Peering
resource "aws_ec2_transit_gateway_route_table" "primary_peering" {
  transit_gateway_id = var.primary_transit_gateway_id

  tags = {
    Name = "${var.name}-primary-peering-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "primary_peering" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_peering.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.this]
}

# Steer incoming cross-region spoke traffic through Suricata NVA Inspection VPC
resource "aws_ec2_transit_gateway_route" "primary_peering_to_inspection" {
  for_each                       = toset(var.primary_spoke_cidrs)
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = var.primary_inspection_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_peering.id
}

# Optional: Steer Peer Region internet traffic (0.0.0.0/0) through Suricata NVA -> Central Egress NAT
resource "aws_ec2_transit_gateway_route" "primary_peering_default_to_inspection" {
  count                          = var.peer_centralized_egress ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.primary_inspection_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_peering.id
}

# Zero-Trust Loop & Infra Protection: Blackhole peer CIDRs & infra CIDRs on incoming peering RT
resource "aws_ec2_transit_gateway_route" "primary_peering_blackhole_peer" {
  for_each                       = toset(var.peer_vpc_cidrs)
  destination_cidr_block         = each.value
  blackhole                      = true
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_peering.id
}

resource "aws_ec2_transit_gateway_route" "primary_peering_blackhole_infra" {
  for_each                       = toset(var.primary_blackhole_cidrs)
  destination_cidr_block         = each.value
  blackhole                      = true
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_peering.id
}

# Post-Inspection -> Peering: Route inspected traffic destined for Peer Region across Peering Attachment
resource "aws_ec2_transit_gateway_route" "primary_post_inspection_to_peer" {
  for_each                       = toset(var.peer_vpc_cidrs)
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this.id
  transit_gateway_route_table_id = var.primary_post_inspection_route_table_id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.this]
}

# ----------------------------------------------------------------------
# Peer Region Route Tables, Associations, Propagations & Static Routes
# ----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route_table" "peer_spoke" {
  provider           = aws.peer
  transit_gateway_id = aws_ec2_transit_gateway.peer.id

  tags = {
    Name = "${var.name}-${var.peer_region}-spoke-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "peer_peering" {
  provider           = aws.peer
  transit_gateway_id = aws_ec2_transit_gateway.peer.id

  tags = {
    Name = "${var.name}-${var.peer_region}-peering-rt"
  }
}

# Associate Peer Spoke VPCs with Peer Spoke TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "peer_spokes" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.peer_spokes)
  provider                       = aws.peer
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.peer_spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.peer_spoke.id
}

# Propagate Peer Spokes into Peer Spoke RT (for intra-peer-region VPC communication if multiple spokes)
resource "aws_ec2_transit_gateway_route_table_propagation" "peer_spoke_to_spoke" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.peer_spokes)
  provider                       = aws.peer
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.peer_spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.peer_spoke.id
}

# Associate Peer-side Peering Attachment with Peer Peering TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "peer_peering" {
  provider                       = aws.peer
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.peer_peering.id
}

# Propagate Peer Spoke CIDRs into Peer Peering RT so incoming cross-region traffic reaches Peer VPCs
resource "aws_ec2_transit_gateway_route_table_propagation" "peer_spoke_to_peering" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.peer_spokes)
  provider                       = aws.peer
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.peer_spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.peer_peering.id
}

# Route Primary Spoke CIDRs from Peer Spoke RT across Peering Attachment
resource "aws_ec2_transit_gateway_route" "peer_spoke_to_primary" {
  for_each                       = toset(var.primary_spoke_cidrs)
  provider                       = aws.peer
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.peer_spoke.id
}

# Optional: Route 0.0.0.0/0 from Peer Spoke RT across Peering Attachment (Centralized Inspection & Egress)
resource "aws_ec2_transit_gateway_route" "peer_spoke_default_to_primary" {
  count                          = var.peer_centralized_egress ? 1 : 0
  provider                       = aws.peer
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.peer_spoke.id
}
