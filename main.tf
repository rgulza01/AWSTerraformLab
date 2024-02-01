provider "aws" {
    profile = "default"
    region = "eu-west-2"
}
resource "aws_instance" "demo1" {
    ami = var.ami
    instance_type = "t2.micro"
    key_name      = "m1lab"
    tags = {
      name = var.project_name
    }
}

resource "aws_s3_bucket" "terraform_bucket" {
  bucket = var.s3_bucket_name
}