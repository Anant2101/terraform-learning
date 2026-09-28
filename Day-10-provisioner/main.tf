provider "aws" {
  region  = "us-east-1"
  profile = "dev_profile"
}


# --------------------------------------------------
# VPC
# --------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Provisioner-VPC"
  }
}


# --------------------------------------------------
# Public Subnet
# --------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Provisioner-Public-Subnet"
  }
}


# --------------------------------------------------
# Internet Gateway
# --------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Provisioner-IGW"
  }
}


# --------------------------------------------------
# Route Table
# --------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Provisioner-Public-RT"
  }
}


# --------------------------------------------------
# Route Table Association
# --------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# --------------------------------------------------
# Security Group
# --------------------------------------------------

resource "aws_security_group" "web" {

  name   = "terraform-provisioner-sg"
  vpc_id = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Provisioner-SG"
  }
}


# --------------------------------------------------
# EC2 Instance
# --------------------------------------------------

resource "aws_instance" "server" {

  # Ubuntu 22.04 AMI in us-east-1
  ami = "ami-0261755bbcb8c4a84"

  instance_type = "t2.micro"

  # Key pair that you created in AWS Console
  key_name = "terraform-provisioner-key"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "Terraform-Provisioner-Server"
  }
}


# --------------------------------------------------
# Copy script.sh to EC2
# --------------------------------------------------

resource "null_resource" "copy_script" {

  connection {
    type = "ssh"

    host = aws_instance.server.public_ip

    user = "ubuntu"

    private_key = file("${path.module}/terraform-provisioner-key.pem")

    timeout = "5m"
  }


  provisioner "file" {

    source = "${path.module}/script.sh"

    destination = "/tmp/script.sh"
  }


  depends_on = [
    aws_instance.server
  ]

}


# --------------------------------------------------
# Execute script.sh on EC2
# --------------------------------------------------

resource "null_resource" "run_script" {

  connection {
    type = "ssh"

    host = aws_instance.server.public_ip

    user = "ubuntu"

    private_key = file("${path.module}/terraform-provisioner-key.pem")

    timeout = "5m"
  }


  provisioner "remote-exec" {

    inline = [

      "chmod +x /tmp/script.sh",

      "sudo /tmp/script.sh"

    ]
  }


  depends_on = [
    null_resource.copy_script
  ]


  # Re-run when script.sh changes
  triggers = {

    script_hash = filemd5(
      "${path.module}/script.sh"
    )

  }

}
