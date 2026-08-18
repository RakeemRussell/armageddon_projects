### ALB SECURITY GROUP (Bonus-B)
resource "aws_security_group" "sg_alb_bonus_b" {
  name        = "sg_alb_bonus_b"
  description = "Bonus-B public ALB - 80/443 from internet, forwards to private EC2 on 80"
  vpc_id      = aws_vpc.vpc_resource.id

  tags = {
    Name = "sg_alb_bonus_b"
  }
}

### ALB INBOUND RULES
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_80" {
  security_group_id = aws_security_group.sg_alb_bonus_b.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 80
  ip_protocol        = "tcp"
  to_port            = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_443" {
  security_group_id = aws_security_group.sg_alb_bonus_b.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 443
  ip_protocol        = "tcp"
  to_port            = 443
}

### ALB OUTBOUND RULE
# Scoped to the private EC2's SG on the app port only - not 0.0.0.0/0 -
# since the ALB's only job is forwarding to that one target.
resource "aws_vpc_security_group_egress_rule" "alb_egress_to_private_ec2" {
  security_group_id            = aws_security_group.sg_alb_bonus_b.id
  referenced_security_group_id = aws_security_group.sg_ec2_private_bonus_a.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

### NEW INBOUND RULE ON THE EXISTING PRIVATE EC2 SG (Bonus-A)
# This is the only change to sg_ec2_private_bonus_a itself: it previously had
# zero inbound rules (SSM-only). This opens port 80, but only from the ALB's
# security group - never from the internet directly.
resource "aws_vpc_security_group_ingress_rule" "private_ec2_ingress_from_alb" {
  security_group_id            = aws_security_group.sg_ec2_private_bonus_a.id
  referenced_security_group_id = aws_security_group.sg_alb_bonus_b.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}
