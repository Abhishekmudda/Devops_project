resource "aws_subnet" "my_subnets" {
  count = length(var.subnet_cidr_block)
  vpc_id = var.vpc_id
  cidr_block = element(var.subnet_cidr_block, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.subnet_name}-${count.index + 1}-${element(data.aws_availability_zones.available.names, count.index)}"
    kubernetes.io/role/elb = "1"
    Environment = "dev"
  }
}

data "aws_availability_zones" "available" {
    state = "available"
}