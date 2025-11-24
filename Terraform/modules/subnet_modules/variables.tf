variable "subnet_name" {
  type = string
}

variable "subnet_cidr_block" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type = map(any)
}