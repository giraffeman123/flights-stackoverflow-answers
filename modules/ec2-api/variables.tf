variable "mandatory_tags" {
  type = object({})
}

variable "name" {
  type = string
}

variable "app_port" {
  type = number
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_key_name" {
  type = string
}

variable "ec2_sg_ingress_rules" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}
