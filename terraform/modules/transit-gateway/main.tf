# Transit Gateway 
resource "aws_ec2_transit_gateway" "transit_gateway" {    
  description = var.description
  tags = {
    Name = var.name
  }
}

# Transit Gateway Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_1" {
  count = length(var.attachments)
  subnet_ids         = var.attachments[count.index].subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = var.attachments[count.index].vpc_id
}