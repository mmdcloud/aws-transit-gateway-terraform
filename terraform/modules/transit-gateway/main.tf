# ----------------------------------------------------------------------
# Transit Gateway
# ----------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "transit_gateway" {
  description                     = var.description
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = var.name
  }
}

# ----------------------------------------------------------------------
# VPC Attachments
# ----------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "spokes" {
  count              = length(var.spoke_attachments)
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = var.spoke_attachments[count.index].vpc_id
  subnet_ids         = var.spoke_attachments[count.index].subnet_ids

  tags = {
    Name = try(var.spoke_attachments[count.index].name != null ? var.spoke_attachments[count.index].name : "${var.name}-spoke-${count.index + 1}", "${var.name}-spoke-${count.index + 1}")
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id                 = var.egress_attachment.vpc_id
  subnet_ids             = var.egress_attachment.subnet_ids
  appliance_mode_support = "enable"

  tags = {
    Name = try(var.egress_attachment.name != null ? var.egress_attachment.name : "${var.name}-egress", "${var.name}-egress")
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  count                  = var.inspection_attachment != null ? 1 : 0
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id                 = var.inspection_attachment.vpc_id
  subnet_ids             = var.inspection_attachment.subnet_ids
  appliance_mode_support = "enable"

  tags = {
    Name = try(var.inspection_attachment.name != null ? var.inspection_attachment.name : "${var.name}-inspection", "${var.name}-inspection")
  }
}

# ----------------------------------------------------------------------
# Transit Gateway Route Tables
# ----------------------------------------------------------------------
# Spoke Route Table: for outbound traffic from workload VPCs
resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "${var.name}-spoke-rt"
  }
}

# Post-Inspection Route Table: for traffic after inspection by NVA
resource "aws_ec2_transit_gateway_route_table" "post_inspection" {
  count              = var.inspection_attachment != null ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "${var.name}-post-inspection-rt"
  }
}

# Egress Route Table: for return traffic from the central NAT Gateway
resource "aws_ec2_transit_gateway_route_table" "egress" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "${var.name}-egress-rt"
  }
}

# ----------------------------------------------------------------------
# Route Table Associations
# ----------------------------------------------------------------------
# Associate Spoke attachments with Spoke TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "spokes" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.spokes)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Associate Egress attachment with Egress TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "egress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

# Associate Inspection attachment with Post-Inspection TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  count                          = var.inspection_attachment != null ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection[0].id
}

# ----------------------------------------------------------------------
# Route Table Propagations
# ----------------------------------------------------------------------
# Without inspection: Propagate Spoke CIDRs directly into Spoke TGW Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_spoke" {
  count                          = var.inspection_attachment == null ? length(aws_ec2_transit_gateway_vpc_attachment.spokes) : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# With inspection: Propagate Spoke CIDRs into Post-Inspection Route Table (so inspected traffic reaches spokes)
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_post_inspection" {
  count                          = var.inspection_attachment != null ? length(aws_ec2_transit_gateway_vpc_attachment.spokes) : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection[0].id
}

# Without inspection: Propagate Spoke CIDRs directly into Egress TGW Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_egress" {
  count                          = var.inspection_attachment == null ? length(aws_ec2_transit_gateway_vpc_attachment.spokes) : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

# ----------------------------------------------------------------------
# Transit Gateway Routes
# ----------------------------------------------------------------------

# 1. Spoke Route Table Routes:
# When inspection is active: Route 0.0.0.0/0 to Inspection VPC Attachment
resource "aws_ec2_transit_gateway_route" "spoke_default_to_inspection" {
  count                          = var.inspection_attachment != null ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# When inspection is active: Route 10.0.0.0/8 (East-West Spoke-to-Spoke) to Inspection VPC Attachment
resource "aws_ec2_transit_gateway_route" "spoke_rfc1918_to_inspection" {
  count                          = var.inspection_attachment != null ? 1 : 0
  destination_cidr_block         = "10.0.0.0/8"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Fallback: When inspection is disabled, route 0.0.0.0/0 directly to Egress VPC Attachment
resource "aws_ec2_transit_gateway_route" "spoke_to_egress_nat" {
  count                          = var.inspection_attachment == null ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# 2. Post-Inspection Route Table Routes:
# Route 0.0.0.0/0 to Egress VPC Attachment (inspected internet traffic proceeds to NAT Gateway)
resource "aws_ec2_transit_gateway_route" "post_inspection_to_egress" {
  count                          = var.inspection_attachment != null ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection[0].id
}

# 3. Egress Route Table Routes:
# When inspection is active: Route return traffic (10.0.0.0/8) to Inspection VPC Attachment for inbound inspection
resource "aws_ec2_transit_gateway_route" "egress_return_to_inspection" {
  count                          = var.inspection_attachment != null ? 1 : 0
  destination_cidr_block         = "10.0.0.0/8"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}
