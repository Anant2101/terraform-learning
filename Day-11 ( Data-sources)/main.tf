provider "aws" {
  region  = "us-east-1"
  profile = "dev_profile"
}

# --------------------------------------------------
# DATA SOURCE 1: Find an existing subnet
# --------------------------------------------------

data "aws_subnet" "name" {
  filter {
    name   = "tag:Name"
    values = ["dev"]
  }
}

# --------------------------------------------------
# DATA SOURCE 2: Find the latest Amazon Linux 2 AMI
# --------------------------------------------------

data "aws_ami" "amzlinux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --------------------------------------------------
# RESOURCE: Create EC2 instance
# --------------------------------------------------

resource "aws_instance" "name" {
  ami           = data.aws_ami.amzlinux.id
  instance_type = "t2.micro"

  subnet_id = data.aws_subnet.name.id

  tags = {
    Name = "Data-Source-EC2"
  }
}

# --------------------------------------------------
# OUTPUTS
# --------------------------------------------------

output "subnet_id" {
  description = "ID of the existing subnet"
  value       = data.aws_subnet.name.id
}

output "subnet_cidr" {
  description = "CIDR block of the existing subnet"
  value       = data.aws_subnet.name.cidr_block
}

output "subnet_az" {
  description = "Availability Zone of the existing subnet"
  value       = data.aws_subnet.name.availability_zone
}

output "ami_id" {
  description = "AMI ID selected by the data source"
  value       = data.aws_ami.amzlinux.id
}

output "ami_name" {
  description = "AMI name selected by the data source"
  value       = data.aws_ami.amzlinux.name
}

output "instance_id" {
  description = "ID of the newly created EC2 instance"
  value       = aws_instance.name.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.name.private_ip
}
