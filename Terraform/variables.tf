variable "region" {
  type = string
}
variable "vpc_cidr" {
  description = "Enter VPC CIDR range"
  type        = string
}

variable "vpc_name" {
  description = "Enter VPC name"
  type        = string
}

variable "public_subnet_name" {
  type = string
}

variable "public_subnet_cidr" {
  type = list(string)
}

variable "private_subnet_name" {
  type = string
}

variable "private_subnet_cidr" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "eks_version" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "node_type" {
  type = string
}

variable "chart_version" {
  type = string
}