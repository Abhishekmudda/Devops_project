resource "local_file" "ansible_yaml" {
  content = templatefile("${path.module}/output-values.yml.tpl", {
    vpc_id       = module.my_vpc.vpc_id
    cluster_name = aws_eks_cluster.my_cluster.name
    bastion_ip   = aws_instance.My_EC2_instance.public_ip
  })
  filename = "./vars.yml"
}