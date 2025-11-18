output "vpc_id" {
  value = module.my_vpc.vpc_id
}

output "public_subnet_id" {
  value = module.public_subnet[*].subnet_id
}

output "private_subnet_id" {
  value = module.private_subnet[*].subnet_id
}

output "Bastion_ip" {
  value = aws_instance.My_EC2_instance.public_ip
}
# output "alb_controller_iam_role_arn" {
#   value = aws_iam_role.alb_controller_role.arn
# }

# output "oidc_provider_arn" {
#   value = aws_iam_openid_connect_provider.eks.arn
# }
