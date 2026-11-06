output "instance1_private_ip" {
  value = module.instance1.private_ip
}

output "instance2_private_ip" {
  value = module.instance2.private_ip
}

output "instance3_private_ip" {
  value = module.instance3.private_ip
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
