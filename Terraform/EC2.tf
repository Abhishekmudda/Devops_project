##Bastion EC2 Instance###
resource "aws_instance" "My_EC2_instance" {
  ami                         = "ami-0ecb62995f68bb549"
  instance_type               = "t2.micro"
  subnet_id                   = module.public_subnet.subnet_id[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg-group.id]
  key_name                    = var.key_name
  tags = {
    Name        = "Bastion_EC2"
    Environment = "dev"
  }
}

##security group for BAstion EC2##
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

##IAM Role & policies for Bastion EC2##

resource "aws_iam_role" "Bastion_ec2_role" {
  name = "BastionEKSRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = ({
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    })
  })
}


resource "aws_iam_policy" "Bastion_policy" {
  name = "BastionEKSPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.Bastion_ec2_role.name
  policy_arn = aws_iam_policy.Bastion_policy.arn
}
