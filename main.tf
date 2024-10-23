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

# module "imported-vpc" {
#   source = "./modules/imported-vpc"
#   vpc_id = var.vpc_id
# }

module "vpc" {
  source                     = "./modules/new-vpc"
  mandatory_tags             = module.tags.mandatory_tags
  vpc_cidr_block             = "10.0.0.0/16"
  public_subnets_cidr_block  = ["10.0.0.0/20", "10.0.128.0/20"]
  private_subnets_cidr_block = ["10.0.16.0/20", "10.0.144.0/20"]
}

module "api" {
  source              = "./modules/api"
  mandatory_tags      = module.tags.mandatory_tags
  name                = "fsa-api"
  app_port            = 3000
  db_host             = "flight-db.xaldigital.mx"
  db_user             = "root"
  db_pwd              = "holamundo123"
  db_name             = "flight-db"
  answer_endpoint     = "https://api.stackexchange.com/2.2/search?order=desc&sort=activity&intitle=perl&site=stackoverflow"
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.public_subnets_ids
  public_subnets_ids  = module.vpc.public_subnets_ids
  health_check_path   = "/api"
  ec2_instance_type   = "t2.micro"
  ec2_key_name        = "aws-test"
}

module "webapp" {
  source              = "./modules/webapp"
  mandatory_tags      = module.tags.mandatory_tags
  name                = "fsa-webapp"
  app_port            = 8080
  fsa_api_base_url    = module.api.alb_dns
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  public_subnets_ids  = module.vpc.public_subnets_ids
  health_check_path   = "/home"
  ec2_instance_type   = "t2.micro"
  ec2_key_name        = "aws-test"
}