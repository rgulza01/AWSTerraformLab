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

# RDS security group
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "RDS security group"
}

# RDS security group rules
resource "aws_security_group_rule" "ec2_to_rds" {
  security_group_id        = aws_security_group.rds_sg.id
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.allow_ssh.id
}

resource "aws_security_group_rule" "rds_to_ec2" {
  security_group_id        = aws_security_group.allow_ssh.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_sg.id
}

# RDS resources
resource "aws_db_subnet_group" "subnet_group" {
  name       = "my-subnet-group"
  subnet_ids = [var.subnet_id_1, var.subnet_id_2, var.subnet_id_3]
}

resource "aws_db_instance" "db_instance" {
  engine                  = "mysql"
  instance_class          = "db.t2.micro"
  username                = "admin"
  password                = "password"
  allocated_storage       = 20
  storage_type            = "gp2"
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 0
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.subnet_group.name
}

# Outputs
output "vm_public_ip" {
  value = aws_instance.demo1.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.db_instance.endpoint
}
