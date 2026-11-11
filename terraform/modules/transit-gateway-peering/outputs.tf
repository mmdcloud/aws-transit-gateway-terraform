output "peer_transit_gateway_id" {
  value       = aws_ec2_transit_gateway.peer.id
  description = "ID of the Peer Region Transit Gateway"
}

output "peer_transit_gateway_arn" {
  value       = aws_ec2_transit_gateway.peer.arn
  description = "ARN of the Peer Region Transit Gateway"
}

output "peering_attachment_id" {
  value       = aws_ec2_transit_gateway_peering_attachment.this.id
  description = "ID of the Inter-Region Transit Gateway Peering Attachment"
}

output "primary_peering_route_table_id" {
  value       = aws_ec2_transit_gateway_route_table.primary_peering.id
  description = "ID of the Primary Region Peering Route Table"
}

output "peer_spoke_route_table_id" {
  value       = aws_ec2_transit_gateway_route_table.peer_spoke.id
  description = "ID of the Peer Region Spoke Route Table"
}

output "peer_peering_route_table_id" {
  value       = aws_ec2_transit_gateway_route_table.peer_peering.id
  description = "ID of the Peer Region Peering Route Table"
}

output "peer_spoke_attachment_ids" {
  value       = aws_ec2_transit_gateway_vpc_attachment.peer_spokes[*].id
  description = "Attachment IDs for Peer Spoke VPCs"
}
