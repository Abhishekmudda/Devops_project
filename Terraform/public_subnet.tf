module "public_subnet" {
  source            = "./modules/subnet_modules"
  subnet_name       = var.public_subnet_name
  subnet_cidr_block = var.public_subnet_cidr
  vpc_id            = module.my_vpc.vpc_id
  val = "1"
  depends_on = [module.my_vpc]
}