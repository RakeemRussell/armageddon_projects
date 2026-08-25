### CODEARTIFACT PIP MIRROR
# CodeArtifact fetches from PyPI using AWS's own infrastructure - not from
# inside your VPC. The private EC2 only ever talks to the CodeArtifact
# endpoints (see the two new interface endpoints in 22-vpc-endpoints.tf);
# PyPI itself is never reachable from, or touched by, the private subnet.
data "aws_caller_identity" "current" {}

resource "aws_codeartifact_domain" "lab_domain" {
  domain = "lab-domain"
}

resource "aws_codeartifact_repository" "pip_mirror" {
  repository = "pip-mirror"
  domain     = aws_codeartifact_domain.lab_domain.domain

  external_connections {
    external_connection_name = "public:pypi"
  }
}
