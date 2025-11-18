module "my_vpc" {
  source   = "./modules/vpc_modules"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
}