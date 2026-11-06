resource "aws_instance" "instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address  
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_groups
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  source_dest_check           = var.source_dest_check

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}
