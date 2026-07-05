### 
resource "aws_route_table" "rtb_resource" {
  vpc_id = aws_vpc.vpc_resource.id

  tags = {
    Name = "rtb_resource"
  }
}

resource "aws_route" "igw_route" {
  route_table_id            = aws_route_table.rtb_resource.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw_resource.id
}

resource "aws_route_table_association" "rtb_association" {
  subnet_id      = aws_subnet.public_subnet_resource.id
  route_table_id = aws_route_table.rtb_resource.id
}