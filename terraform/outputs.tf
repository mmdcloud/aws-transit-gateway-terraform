output "instance1_ip" {
  value = aws_instance.instance1.public_ip
}

output "instance2_ip" {
  value = aws_instance.instance2.public_ip
}

output "instance3_ip" {
  value = aws_instance.instance3.public_ip
}
