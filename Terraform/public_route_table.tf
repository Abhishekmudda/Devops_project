resource "aws_route_table" "public_route_table" {
  vpc_id = module.my_vpc.vpc_id
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = module.public_subnet.subnet_id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}
