# the private subnets currently have no explicit route table (they're on a implicit 'main' one)
# the gateway endpoint works by injecting a route into a route table,
# so this creates one and associates both private subnets,
# no igw/nat route added, which is what keeps them private

resource "aws_route_table" "rtb_private" {
  vpc_id = aws_vpc.vpc_resource.id

  tags = {
    Name = "rtb_private"
  }
}

resource "aws_route_table_association" "rtb_private_a_association" {
  subnet_id      = aws_subnet.private_subnet_a_resource.id
  route_table_id = aws_route_table.rtb_private.id
}

resource "aws_route_table_association" "rtb_private_b_association" {
  subnet_id      = aws_subnet.private_subnet_b_resource.id
  route_table_id = aws_route_table.rtb_private.id
}