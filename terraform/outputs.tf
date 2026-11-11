output "instance1_private_ip" {
  value = module.instance1.private_ip
}

output "instance2_private_ip" {
  value = module.instance2.private_ip
}

output "instance3_private_ip" {
  value = module.instance3.private_ip
}

output "peer_instance_id" {
  description = "EC2 Instance ID of the Peer Region test instance (vpc4-peer)"
  value       = module.peer_instance.id
}

output "peer_instance_private_ip" {
  description = "Private IP of the Peer Region test instance (vpc4-peer)"
  value       = module.peer_instance.private_ip
}

output "nva_instance_id" {
  description = "EC2 Instance ID of the Suricata NVA Appliance"
  value       = module.nva.id
}

output "nva_private_ip" {
  description = "Private IP of the Suricata NVA Appliance ENI"
  value       = module.nva.private_ip
}

output "inspection_vpc_id" {
  description = "VPC ID of the Centralized Inspection VPC"
  value       = module.inspection_vpc.vpc_id
}

output "tgw_inspection_attachment_id" {
  description = "Transit Gateway Attachment ID for Inspection VPC"
  value       = module.transit_gateway.inspection_attachment_id
}

output "tgw_post_inspection_route_table_id" {
  description = "Transit Gateway Post-Inspection Route Table ID"
  value       = module.transit_gateway.post_inspection_route_table_id
}

output "peer_vpc_id" {
  description = "VPC ID of the Peer Region Spoke VPC (vpc4-peer)"
  value       = module.peer_vpc.vpc_id
}

output "peer_transit_gateway_id" {
  description = "Transit Gateway ID in the Peer Region"
  value       = module.transit_gateway_peering.peer_transit_gateway_id
}

output "tgw_peering_attachment_id" {
  description = "Inter-Region Transit Gateway Peering Attachment ID"
  value       = module.transit_gateway_peering.peering_attachment_id
}

output "tgw_primary_peering_route_table_id" {
  description = "Primary Region TGW Peering Route Table ID"
  value       = module.transit_gateway_peering.primary_peering_route_table_id
}

output "tgw_peer_spoke_route_table_id" {
  description = "Peer Region TGW Spoke Route Table ID"
  value       = module.transit_gateway_peering.peer_spoke_route_table_id
}
