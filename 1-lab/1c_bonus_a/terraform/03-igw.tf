resource "aws_internet_gateway" "igw_resource" {
  vpc_id = aws_vpc.vpc_resource.id

  tags = {
    Name = "igw_resource"
  }
}