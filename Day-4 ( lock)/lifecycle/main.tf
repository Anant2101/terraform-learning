resource "aws_instance" "web" {
  ami           = "ami-0e34b50e714a297f1"
  instance_type = "t2.micro"

  #   lifecycle {
  #     prevent_destroy = true
  #   }
}
