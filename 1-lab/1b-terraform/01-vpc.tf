resource "aws_vpc" "vpc_resource" {
  cidr_block       = "10.90.0.0/16"

  tags = {
    Name = "vpc_resource"
  }
}