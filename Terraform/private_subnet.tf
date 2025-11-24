module "private_subnet" {
  source            = "./modules/subnet_modules"
  subnet_name       = var.private_subnet_name
  subnet_cidr_block = var.private_subnet_cidr
  vpc_id            = module.my_vpc.vpc_id
  depends_on        = [module.my_vpc]
  tags = var.private_subnet_tags
}
