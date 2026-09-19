resource "aws_vpc" "vpc_resource" {
  cidr_block = "10.90.0.0/16"

  # Required for private_dns_enabled = true on the interface endpoints in
  # 22-vpc-endpoints.tf - without these, AWS rejects endpoint creation.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_resource"
  }
}