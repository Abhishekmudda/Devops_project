resource "aws_instance" "My_EC2_instance" {
  ami                         = "ami-0150ccaf51ab55a51"
  instance_type               = "t2.micro"
  subnet_id                   = module.public_subnet.subnet_id[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg-group.id]
  key_name                    = aws_key_pair.student_key_pair.key_name
  tags = {
    Name = "Bastion_EC2"
  }
}

resource "aws_security_group" "sg-group" {
  vpc_id      = module.my_vpc.vpc_id
  description = "allow ssh, http and https"

  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# data "templatefile" "inventory" {
#   template = file("${path.module}/inventory.tpl")
#   vars = {
#     public_ip        = aws_instance.my_ec2.public_ip
#     private_key_path = "~/.ssh/mykey.pem"
#   }
#   depends_on = [ aws_instance.My_EC2_instance ]
# }

# resource "local_file" "ansible_inventory" {
#   content  = data.templatefile.inventory
#   filename = "${path.module}/inventory.ini"
#   depends_on = [ data.templatefile.inventory ]
# }