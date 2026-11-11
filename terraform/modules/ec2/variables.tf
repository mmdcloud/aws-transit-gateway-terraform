variable "name" {
  type        = string
  description = "Name tag of the EC2 instance"
}

variable "ami" {
  type        = string
  description = "AMI ID to launch"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Whether to associate a public IP address"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Key pair name (optional when using AWS SSM Session Manager)"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to launch instance in"
}

variable "security_groups" {
  type        = list(string)
  description = "List of security group IDs"
}

variable "user_data" {
  type        = string
  default     = null
  description = "User data script"
}

variable "user_data_base64" {
  type        = string
  default     = null
  description = "Base64-encoded user data script"
}

variable "iam_instance_profile" {
  type        = string
  default     = null
  description = "IAM instance profile name"
}

variable "source_dest_check" {
  type        = bool
  default     = true
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for the instance"
}
