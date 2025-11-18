resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "student_key_pair" {
  key_name   = "student-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_s3_object" "private_key" {
  bucket  = "abhishek-112233-bucket"
  key     = "keys/id_rsa"
  content = tls_private_key.ssh_key.private_key_pem
}

resource "aws_s3_object" "public_key" {
  bucket  = "abhishek-112233-bucket"
  key     = "keys/id_rsa_pub"
  content = tls_private_key.ssh_key.public_key_pem
}

resource "local_file" "ssh_key" {
  filename = "${path.module}/bastion_ssh_key"
  content  = tls_private_key.ssh_key.private_key_pem
}
