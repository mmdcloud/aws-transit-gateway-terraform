output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.transit_gateway.id
}

output "transit_gateway_arn" {
  value = aws_ec2_transit_gateway.transit_gateway.arn
}

output "spoke_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.spoke.id
}

output "egress_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.egress.id
}

output "post_inspection_route_table_id" {
  value = try(aws_ec2_transit_gateway_route_table.post_inspection[0].id, null)
}

output "spoke_attachment_ids" {
  value = aws_ec2_transit_gateway_vpc_attachment.spokes[*].id
}

output "egress_attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.egress.id
}

output "inspection_attachment_id" {
  value = try(aws_ec2_transit_gateway_vpc_attachment.inspection[0].id, null)
}
