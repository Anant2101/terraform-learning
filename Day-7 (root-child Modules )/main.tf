module "dev" {
  source        = "./modules/ec2"
  ami           = "ami-0e34b50e714a297f1"
  instance_type = "t2.micro"
}

module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "terraform-vpc"
}
