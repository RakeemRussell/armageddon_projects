### VPC INTERFACE ENDPOINTS
# The 6 interface endpoints
#(ssm, ec2messages, ssmmessages, logs, secretsmanager, kms)
#plus the S3 gateway endpoint. Used via for_each over a local map so all 6 interface endpoints
#share one resource block instead of six near-identical ones.
#private_dns_enabled = true, means the existing boto3 calls in app.py
#(secretsmanager.client(...), ssm.client(...)) don't change at all;
#DNS just quietly resolves to the private endpoint IP instead of the public one.

locals {
  interface_endpoint_services = {
    ssm            = "ssm"            # Session Manager control channel
    ec2messages    = "ec2messages"    # Session Manager - EC2 instance messages
    ssmmessages    = "ssmmessages"    # Session Manager - session data channel
    logs           = "logs"           # CloudWatch Logs (agent log delivery)
    secretsmanager = "secretsmanager" # app pulls DB creds from Secrets Manager
    kms            = "kms"            # decrypts the secret, if it's KMS-encrypted
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.vpc_resource.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_subnet_a_resource.id,
    aws_subnet.private_subnet_b_resource.id
  ]

  security_group_ids = [aws_security_group.sg_vpc_endpoints.id]

  tags = {
    Name = "vpce-${each.key}"
  }
}

### VPC GATEWAY ENDPOINT (S3)
# Gateway endpoints work differently from interface endpoints - instead of
# an ENI with an IP, this injects a route into the associated route table
# so traffic to S3 (dnf/AL2023 repos, future app data) never leaves the AWS
# network or touches an interface endpoint.

resource "aws_vpc_endpoint" "s3_gateway_endpoint" {
  vpc_id            = aws_vpc.vpc_resource.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.rtb_private.id]

  tags = {
    Name = "vpce-s3-gateway"
  }
}