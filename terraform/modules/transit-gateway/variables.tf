variable "name" {
  type        = string
  description = "Name for the Transit Gateway"
}

variable "description" {
  type        = string
  default     = "Transit Gateway with Centralized NAT"
  description = "Description for the Transit Gateway"
}

variable "spoke_attachments" {
  type = list(object({
    vpc_id     = string
    subnet_ids = list(string)
    name       = optional(string)
  }))
  default     = []
  description = "List of spoke VPC attachments"
}

variable "egress_attachment" {
  type = object({
    vpc_id     = string
    subnet_ids = list(string)
    name       = optional(string)
  })
  description = "Egress VPC attachment"
}

variable "inspection_attachment" {
  type = object({
    vpc_id     = string
    subnet_ids = list(string)
    name       = optional(string)
  })
  default     = null
  description = "Optional Inspection VPC attachment for centralized NVA firewall/IDS"
}

