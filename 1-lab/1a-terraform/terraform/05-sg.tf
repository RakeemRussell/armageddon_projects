### PUBLIC SECURITY GROUP 
resource "aws_security_group" "sg_resource" {
  name        = "public_sg"
  description = "public subnet security group"
  vpc_id      = aws_vpc.vpc_resource.id

  tags = {
    Name = "public_sg"
  }
}
### PUBLIC INBOUND RULES
resource "aws_vpc_security_group_ingress_rule" "ingress_port_80_rule" {
  security_group_id = aws_security_group.sg_resource.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ingress_port_22_rule" {
  security_group_id = aws_security_group.sg_resource.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
### PUBLIC OUTBOUND RULES
resource "aws_vpc_security_group_egress_rule" "egress_all_ports_rule" {
  security_group_id = aws_security_group.sg_resource.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
### PRIVATE SECURITY GROUP
resource "aws_security_group" "sg_private_resource" {
  name        = "private_sg"
  description = "private subnet security group"
  vpc_id      = aws_vpc.vpc_resource.id

  tags = {
    Name = "private_sg"
  }
}
### PRIVATE INBOUND RULES
resource "aws_vpc_security_group_ingress_rule" "ingress_port_3306_rule" {
  security_group_id = aws_security_group.sg_private_resource.id
  cidr_ipv4         = aws_vpc.vpc_resource.cidr_block
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}
### PRIVATE OUTBOUND RULES
resource "aws_vpc_security_group_egress_rule" "egress_all_ports_rule_private" {
  security_group_id = aws_security_group.sg_private_resource.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}