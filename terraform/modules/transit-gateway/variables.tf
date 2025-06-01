variable "attachments" {
  type = list(object({
    vpc_id                 = string
    subnet_ids   = list(string)   
  }))  
}
variable "name" {
  type = string
  
}

variable "description" {
  type = string
  default = ""      
}