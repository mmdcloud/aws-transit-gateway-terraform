output "id" {
  value = aws_instance.instance.id
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

output "primary_network_interface_id" {
  value = aws_instance.instance.primary_network_interface_id
}
