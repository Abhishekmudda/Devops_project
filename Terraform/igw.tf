resource "aws_internet_gateway" "igw" {
  vpc_id = module.my_vpc.vpc_id
}