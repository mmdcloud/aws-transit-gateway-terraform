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

# ----------------------------------------------------------------------
# Route Table Propagations
# ----------------------------------------------------------------------
# Propagate Spoke CIDRs into Spoke TGW Route Table (East-West traffic between spokes)
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_spoke" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.spokes)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Propagate Spoke CIDRs into Egress TGW Route Table (Return traffic to spokes from NAT GW)
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_egress" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.spokes)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spokes[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

# ----------------------------------------------------------------------
# Transit Gateway Routes
# ----------------------------------------------------------------------
# Route 0.0.0.0/0 in Spoke TGW Route Table to Central Egress VPC Attachment
resource "aws_ec2_transit_gateway_route" "spoke_to_egress_nat" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}
