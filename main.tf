provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_instance" "demo1" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.TF_key.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    project = var.project_name
  }

  depends_on = [aws_key_pair.TF_key] #ensuring that the key is generated first
}


resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "TF_key" {
  key_name   = "TF_key"
  public_key = tls_private_key.rsa.public_key_openssh #public_key_openssh is an attribute 
}


# to access EC2 instances via SSH
resource "local_file" "TF_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf_key"
}


resource "aws_security_group" "allow_ssh" {
  name        = var.security_group_name
  description = "allow ssh access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    project = var.project_name
  }
}
# to verify that the EC2 instance was provisioned successfully and obtain its public IP address directly from the Terraform command-line interface
# also to access the ssh directly 
output "vm_public_ip" {
  value = aws_instance.demo1.public_ip
}
