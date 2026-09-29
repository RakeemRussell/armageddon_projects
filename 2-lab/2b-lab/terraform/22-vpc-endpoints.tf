### VPC INTERFACE ENDPOINTS
# One private, DNS-resolvable path per AWS API the private EC2 needs to call.
# private_dns_enabled = true means boto3/AWS CLI calls to the normal public
# endpoint hostname (e.g. secretsmanager.us-east-1.amazonaws.com) transparently
# resolve to the endpoint's private IP inside the VPC - no code changes needed.
locals {
  interface_endpoint_services = {
    ssm                       = "ssm"                       # Session Manager control channel
    ec2messages               = "ec2messages"               # Session Manager - EC2 instance messages
    ssmmessages               = "ssmmessages"               # Session Manager - session data channel
    logs                      = "logs"                      # CloudWatch Logs (agent log delivery)
    secretsmanager            = "secretsmanager"            # app pulls DB creds from Secrets Manager
    kms                       = "kms"                       # decrypts the secret, if it's KMS-encrypted
    codeartifact_api          = "codeartifact.api"          # CodeArtifact control plane - login/auth token
    codeartifact_repositories = "codeartifact.repositories" # actual pip package downloads
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.vpc_resource.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
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
