variable "mandatory_tags" {}

variable "name" {
  type = string
}

variable "app_port" {
  type = number
}

variable "fsa_api_base_url" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "private_subnets_ids" {
  type    = list(string)
  default = [""]
}

variable "public_subnets_ids" {
  type    = list(string)
  default = [""]
}

variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_key_name" {
  type = string
}

variable "main_domain_name" {
  type = string
}

variable "static_website_domain" {
  type = string
}

