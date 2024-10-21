module "tags" {
  source          = "./modules/tags"
  application     = "flights-stackoverflow-answers"
  project         = "learn-aws-2"
  team            = "infrastructure"
  environment     = "dev"
  owner           = "giraffeman123"
  project_version = "1.0"
  contact         = "giraffeman123@gmail.com"
  cost_center     = "35009"
  sensitive       = false
}

module "ec2_api" {
  source            = "./modules/ec2-api"
  mandatory_tags    = module.tags.mandatory_tags
  name              = "fsa-api-${module.tags.mandatory_tags.Environment}"
  app_port          = 3000
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  ec2_instance_type = "t2.micro"
  ec2_key_name      = "aws-test"
  ec2_sg_ingress_rules = {
    "app_port" = {
      description = "App port"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "ssh_port" = {
      description = "SSH port"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

module "spring_api" {
  source            = "./modules/ec2-webapp"
  mandatory_tags    = module.tags.mandatory_tags
  name              = "fsa-webapp-${module.tags.mandatory_tags.Environment}"
  app_port          = 8080
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  ec2_instance_type = "t2.micro"
  ec2_key_name      = "aws-test"
  ec2_sg_ingress_rules = {
    "app_port" = {
      description = "App port"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "ssh_port" = {
      description = "SSH port"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}