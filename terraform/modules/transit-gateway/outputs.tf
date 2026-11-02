output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.transit_gateway.id
}

output "spoke_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.spoke.id
}

output "egress_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.egress.id
}

output "spoke_attachment_ids" {
  value = aws_ec2_transit_gateway_vpc_attachment.spokes[*].id
}

output "egress_attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.egress.id
}
