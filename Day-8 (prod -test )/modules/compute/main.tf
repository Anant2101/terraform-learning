resource "aws_instance" "name" {
  instance_type = var.instance_type
  ami           = var.ami
  subnet_id     = var.subnet_id
  tags = {
    Name = var.instance_name
  }
}
