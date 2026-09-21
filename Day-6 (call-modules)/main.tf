module "dev" {
  source        = "../Day-6 (modules)"
  ami           = "ami-0e34b50e714a297f1"
  instance_type = "t2.micro"
}

module "prod" {
  source        = "../Day-6 (modules)"
  ami           = "ami-0e34b50e714a297f1"
  instance_type = "t2.micro"
}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.0.0"
}
