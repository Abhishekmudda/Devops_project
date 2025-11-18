# # ###################################################
# # # Get EKS cluster details
# # ###################################################
# # data "aws_eks_cluster" "eks" {
# #   name = var.cluster_name
# #   depends_on = [
# #     aws_eks_cluster.my_cluster
# #   ]
# # }

# # data "aws_eks_cluster_auth" "eks" {
# #   name = var.cluster_name
# #   depends_on = [
# #     aws_eks_cluster.my_cluster
# #   ]
# # }

# # ###################################################
# # # OIDC Provider (MUST be before IAM role)
# # ###################################################
# # data "tls_certificate" "eks" {
# #   url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
# #   depends_on = [
# #     aws_eks_cluster.my_cluster
# #   ]
# # }

# # resource "aws_iam_openid_connect_provider" "eks" {
# #   url             = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
# #   client_id_list  = ["sts.amazonaws.com"]
# #   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
# # }

# # ###################################################
# # # IAM Role for ALB controller (CORRECT IRSA policy)
# # ###################################################
# # resource "aws_iam_role" "alb_controller_role" {
# #   name = "${var.cluster_name}-alb-controller-role"

# #   assume_role_policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [{
# #       Effect = "Allow"
# #       Principal = {
# #         Federated = aws_iam_openid_connect_provider.eks.arn
# #       }
# #       Action = "sts:AssumeRoleWithWebIdentity"
# #       Condition = {
# #         StringEquals = {
# #           "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
# #         }
# #       }
# #     }]
# #   })
# # }

# # resource "aws_iam_policy" "alb_controller_policy" {
# #   name   = "${var.cluster_name}-alb-controller-policy"
# #   policy = file("${path.module}/iam-policy.json")
# # }

# # resource "aws_iam_role_policy_attachment" "attach_alb_policy" {
# #   role       = aws_iam_role.alb_controller_role.name
# #   policy_arn = aws_iam_policy.alb_controller_policy.arn
# # }

# # ###################################################
# # # Kubernetes Provider
# # ###################################################
# # provider "kubernetes" {
# #   host                   = data.aws_eks_cluster.eks.endpoint
# #   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
# #   token                  = data.aws_eks_cluster_auth.eks.token
# # }

# # ###################################################
# # # Service Account for ALB controller
# # ###################################################
# # resource "kubernetes_service_account" "alb_sa" {
# #   metadata {
# #     name      = "aws-load-balancer-controller"
# #     namespace = "kube-system"
# #     annotations = {
# #       "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
# #     }
# #   }

# #   depends_on = [
# #     aws_iam_openid_connect_provider.eks
# #   ]
# # }

# # ###################################################
# # # Helm Provider
# # ###################################################
# # provider "helm" {}

# # ###################################################
# # # Install AWS ALB Ingress Controller
# # ###################################################
# # resource "helm_release" "alb_controller" {
# #   name       = "aws-load-balancer-controller"
# #   namespace  = "kube-system"
# #   # repository = "oci://public.ecr.aws/aws-eks-charts"
# #   chart      = "${path.module}/aws-load-balancer-controller"
# #   # version    = "1.9.1"

# #   values = [
# #     templatefile("${path.module}/alb_values.yaml.tpl", {
# #       cluster_name = var.cluster_name
# #       region       = var.region
# #     })
# #   ]

# #   depends_on = [
# #     kubernetes_service_account.alb_sa,
# #     aws_iam_role_policy_attachment.attach_alb_policy
# #   ]
# # }


# data "aws_eks_cluster" "eks" {
#   name = var.cluster_name
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = var.cluster_name
# }

# data "tls_certificate" "eks" {
#   url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   url             = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
# }

# resource "aws_iam_role" "alb_controller_role" {
#   name = "${var.cluster_name}-alb-controller-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.eks.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_policy" "alb_controller_policy" {
#   name   = "${var.cluster_name}-alb-controller-policy"
#   policy = file("${path.module}/iam-policy.json")
# }

# resource "aws_iam_role_policy_attachment" "attach_alb_policy" {
#   role       = aws_iam_role.alb_controller_role.name
#   policy_arn = aws_iam_policy.alb_controller_policy.arn
# }


# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# provider "helm" {
#   kubernetes = {
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }


# resource "kubernetes_service_account" "alb_sa" {
#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"

#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
#     }
#   }

#   depends_on = [
#     aws_iam_openid_connect_provider.eks
#   ]
# }

# resource "helm_release" "alb_controller" {
#   name      = "aws-load-balancer-controller"
#   namespace = "kube-system"
#   chart     = "${path.module}/aws-load-balancer-controller"

#   values = [
#     templatefile("${path.module}/alb_values.yaml.tpl", {
#       cluster_name = var.cluster_name
#       region       = var.region
#     })
#   ]

#   depends_on = [
#     kubernetes_service_account.alb_sa,
#     aws_iam_role_policy_attachment.attach_alb_policy
#   ]
# }



