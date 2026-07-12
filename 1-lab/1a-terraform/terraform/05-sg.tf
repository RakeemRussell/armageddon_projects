### PUBLIC SECURITY GROUP 
resource "aws_security_group" "sg_ec2_lab" {
  name        = "sg_ec2_lab"
  description = "public subnet security group"
  vpc_id      = aws_vpc.vpc_resource.id

  tags = {
    Name = "sg_ec2_lab"
  }
}
### PUBLIC INBOUND RULES
resource "aws_vpc_security_group_ingress_rule" "ingress_port_80_rule" {
  security_group_id = aws_security_group.sg_ec2_lab.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ingress_port_22_rule" {
  security_group_id = aws_security_group.sg_ec2_lab.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
### PUBLIC OUTBOUND RULES
resource "aws_vpc_security_group_egress_rule" "egress_all_ports_rule" {
  security_group_id = aws_security_group.sg_ec2_lab.id
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
  referenced_security_group_id = aws_security_group.sg_ec2_lab.id
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