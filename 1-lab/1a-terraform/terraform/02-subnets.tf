### PUBLIC SUBNET ###
resource "aws_subnet" "public_subnet_resource" {
  vpc_id     = aws_vpc.vpc_resource.id
  cidr_block = "10.90.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_subnet_resource"
  }
}

### PRIVATE SUBNET ###
resource "aws_subnet" "private_subnet_resource" {
  vpc_id     = aws_vpc.vpc_resource.id
  cidr_block = "10.90.11.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_subnet_resource"
  }
}