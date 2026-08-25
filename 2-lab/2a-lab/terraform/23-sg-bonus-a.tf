# AWS-managed prefix list for the S3 gateway endpoint in this region.
# Used to scope egress to "S3 addresses only" instead of 0.0.0.0/0.
data "aws_prefix_list" "s3_prefix_list" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

### PRIVATE EC2 SECURITY GROUP (Bonus-A)
# No inbound rules at all. Session Manager reaches the instance through the
# SSM agent's outbound tunnel to the SSM/EC2Messages/SSMMessages endpoints,
# not through an inbound listener, so nothing needs to open a port to reach it.
resource "aws_security_group" "sg_ec2_private_bonus_a" {
  name        = "sg_ec2_private_bonus_a"
  description = "Bonus-A private EC2 - no inbound, SSM-only access"
  vpc_id      = aws_vpc.vpc_resource.id

  tags = {
    Name = "sg_ec2_private_bonus_a"
  }
}

### PRIVATE EC2 OUTBOUND RULES
# 443 to the endpoints SG covers SSM, EC2Messages, SSMMessages, Logs,
# Secrets Manager, and KMS API calls.
resource "aws_vpc_security_group_egress_rule" "egress_443_to_endpoints" {
  security_group_id            = aws_security_group.sg_ec2_private_bonus_a.id
  referenced_security_group_id = aws_security_group.sg_vpc_endpoints.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

# 443 to the S3 prefix list covers S3 Gateway Endpoint traffic (dnf/AL2023
# repos, and any future S3 access), without opening egress to the internet.
resource "aws_vpc_security_group_egress_rule" "egress_443_to_s3" {
  security_group_id = aws_security_group.sg_ec2_private_bonus_a.id
  prefix_list_id    = data.aws_prefix_list.s3_prefix_list.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# 3306 to RDS so the app can reach the database.
resource "aws_vpc_security_group_egress_rule" "egress_3306_to_rds" {
  security_group_id            = aws_security_group.sg_ec2_private_bonus_a.id
  referenced_security_group_id = aws_security_group.sg_private_resource.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

### VPC ENDPOINTS SECURITY GROUP (Bonus-A)
# private_dns_enabled = true on these endpoints overrides AWS API DNS
# resolution (ssm., secretsmanager., logs., etc.) for the WHOLE VPC, not
# just the private subnets - so the public EC2 (sg_ec2_lab) now resolves
# these hostnames to the endpoint too, even though it still has internet
# access of its own. It needs to be allowed in here or every AWS API call
# from the public instance times out.
resource "aws_security_group" "sg_vpc_endpoints" {
  name        = "sg_vpc_endpoints"
  description = "Bonus-A VPC interface endpoints - 443 from both EC2 SGs (private_dns applies VPC-wide)"
  vpc_id      = aws_vpc.vpc_resource.id

  tags = {
    Name = "sg_vpc_endpoints"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_443_from_private_ec2" {
  security_group_id            = aws_security_group.sg_vpc_endpoints.id
  referenced_security_group_id = aws_security_group.sg_ec2_private_bonus_a.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "ingress_443_from_public_ec2" {
  security_group_id            = aws_security_group.sg_vpc_endpoints.id
  referenced_security_group_id = aws_security_group.sg_ec2_lab.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
