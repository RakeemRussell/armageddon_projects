### PUBLIC SUBNET ###
resource "aws_subnet" "public_subnet_resource" {
  vpc_id     = aws_vpc.vpc_resource.id
  cidr_block = "10.90.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_subnet_resource"
  }
}

### PRIVATE SUBNET A ###
resource "aws_subnet" "private_subnet_a_resource" {
  vpc_id     = aws_vpc.vpc_resource.id
  cidr_block = "10.90.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_subnet-a_resource"
  }
}
### PRIVATE SUBNET B ###
resource "aws_subnet" "private_subnet_b_resource" {
  vpc_id     = aws_vpc.vpc_resource.id
  cidr_block = "10.90.20.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_subnet-b_resource"
  }
}