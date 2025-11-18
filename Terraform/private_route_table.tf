
resource "aws_eip" "eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = module.public_subnet.subnet_id[0]
  tags = {
    Name = "NAT-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = module.my_vpc.vpc_id
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = module.private_subnet.subnet_id[count.index]
  route_table_id = aws_route_table.private_route_table.id
}
