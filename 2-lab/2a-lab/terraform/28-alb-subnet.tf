### PUBLIC SUBNET B (Bonus-B) ###
# The ALB requires subnets in at least 2 Availability Zones. The existing
# public_subnet_resource is us-east-1a only - this adds the us-east-1b
# counterpart so the ALB can be created.
resource "aws_subnet" "public_subnet_b_resource" {
  vpc_id                  = aws_vpc.vpc_resource.id
  cidr_block              = "10.90.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet-b_resource"
  }
}

resource "aws_route_table_association" "rtb_association_b" {
  subnet_id      = aws_subnet.public_subnet_b_resource.id
  route_table_id = aws_route_table.rtb_resource.id
}