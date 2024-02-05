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
______________________________________________for the last lab the code as below___________________________________
provider "aws" {
 profile = "default"
 region  = "eu-west-2"
}


resource "aws_instance" "lastlab" {


   count = 2


   ami = var.ami


   instance_type = var.instance_type


   key_name = "m1lab"


   subnet_id         = count.index == 0 ? "subnet-098167b2724e073ab" : "subnet-0f83c27221e24ef2b"


   vpc_security_group_ids = [aws_security_group.instance_sg.id]


   depends_on = [aws_security_group.instance_sg]


}




resource "aws_security_group" "instance_sg" {


 name        = "instance_sg"


 description = "Allow inbound traffic"




 ingress {


   from_port   = 22


   to_port     = 22


   protocol    = "tcp"


   cidr_blocks = ["0.0.0.0/0"]


 }




 ingress {


   from_port   = 80


   to_port     = 80


   protocol    = "tcp"


   cidr_blocks = ["0.0.0.0/0"]


 }




 egress {


   from_port       = 0


   to_port         = 0


   protocol        = "-1"


   cidr_blocks     = ["0.0.0.0/0"]


 }


}




resource "aws_lb" "lb" {


 name               = "nginx-lb"


 internal           = false


 load_balancer_type = "application"


 security_groups    = [aws_security_group.lb_sg.id]


 subnets            = ["subnet-098167b2724e073ab", "subnet-0f83c27221e24ef2b"]


 depends_on = [aws_security_group.lb_sg]


}




resource "aws_lb_target_group" "tg" {


 name     = "nginx-tg"


 port     = 80


 protocol = "HTTP"


 vpc_id   = "vpc-0104e9c1a5a1e1ee4"




 health_check {


   enabled             = true


   interval            = 30


   path                = "/"


   port                = "80"


   protocol            = "HTTP"


   timeout             = 5


   healthy_threshold   = 3


   unhealthy_threshold = 3


 }


}




resource "aws_lb_listener" "front_end" {


 load_balancer_arn = aws_lb.lb.arn


 port              = "80"


 protocol          = "HTTP"


 depends_on = [aws_lb.lb]


 default_action {


   type             = "forward"


   target_group_arn = aws_lb_target_group.tg.arn


 }


}




resource "aws_lb_target_group_attachment" "attach" {


 count            = 2


 target_group_arn = aws_lb_target_group.tg.arn


 target_id        = aws_instance.lastlab[count.index].id


 port             = 80


 depends_on = [aws_lb_target_group.tg]


}




resource "aws_security_group" "lb_sg" {


 name        = "lb_sg"


 description = "Allow inbound traffic"




 ingress {


   from_port   = 80


   to_port     = 80


   protocol    = "tcp"


   cidr_blocks = ["0.0.0.0/0"]


 }




 egress {


   from_port   = 0


   to_port     = 0


   protocol    = "-1"


   cidr_blocks = ["0.0.0.0/0"]


 }


}




output "ec2_public_ip" {


 value = aws_instance.lastlab[*].public_ip


}




output "ec2_dns" {


 value = aws_instance.lastlab[*].public_dns


}




output "lb_dns" {


 value = aws_lb.lb.dns_name


}
