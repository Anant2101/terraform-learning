variable "cidr_block" {

  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "terraform-vpc"
}
