module "ec2_api" {
  source            = "./modules/ec2-api"
  environment       = "dev"
  application       = "merge-sort"
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  ec2_ami_id        = "ami-024e6efaf93d85776"
  ec2_instance_type = "t2.micro"
  ec2_key_name      = "aws-test"
}

module "spring_api" {
    source = "./modules/ec2-webapp"    
    environment = "dev"
    application = "xaldigital"    
    vpc_id = var.vpc_id
    subnet_id = var.subnet_id
    ec2_ami_id = "ami-024e6efaf93d85776"
    ec2_instance_type = "t2.micro"   
    ec2_key_name = "aws-test"
}