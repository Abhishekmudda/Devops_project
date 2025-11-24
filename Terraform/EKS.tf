# resource "aws_eks_cluster" "my_cluster" {
#   name     = var.cluster_name
#   version  = var.eks_version
#   role_arn = aws_iam_role.eks_cluster_role.arn
#   vpc_config {
#     subnet_ids = module.private_subnet.subnet_id
#   }
#   depends_on = [module.private_subnet, aws_iam_role.eks_cluster_role]
# }

# resource "aws_eks_node_group" "nodes" {
#   cluster_name    = aws_eks_cluster.my_cluster.name
#   node_group_name = var.node_group_name
#   node_role_arn   = aws_iam_role.eks_node_role.arn
#   subnet_ids      = module.private_subnet.subnet_id

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   instance_types = [var.node_type]
#   capacity_type  = "ON_DEMAND"

#   depends_on = [aws_eks_cluster.my_cluster, aws_iam_role.eks_node_role]
# }