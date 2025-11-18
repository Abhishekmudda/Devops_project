output "subnet_id" {
  value = aws_subnet.my_subnets[*].id
}