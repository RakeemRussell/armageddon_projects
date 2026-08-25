### IAM ROLE for the Bonus-A private EC2
# Separate role from ec2_notes_role (08-iam.tf) so the private instance's
# permissions are visible and auditable on their own, even though it reuses
# the same trust policy shape.
resource "aws_iam_role" "ec2_notes_private_role" {
  name = "ec2-notes-private-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

### Attach the SAME scoped policy from 08-iam.tf - GetSecretValue on the one
# secret ARN, GetParameter(s) on the specific parameter ARNs, and the scoped
# CloudWatch Logs actions. No new permissions are invented for this role.
resource "aws_iam_role_policy_attachment" "attach_secret_policy_private" {
  role       = aws_iam_role.ec2_notes_private_role.name
  policy_arn = aws_iam_policy.ec2_secrets_policy.arn
}

### Attach AWS's managed SSM policy - this is what lets Session Manager
# connect without SSH. It grants the SSM agent permission to register the
# instance and open the session channel; it does NOT grant broad EC2 access.
resource "aws_iam_role_policy_attachment" "attach_ssm_managed_policy" {
  role       = aws_iam_role.ec2_notes_private_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

### INSTANCE PROFILE
resource "aws_iam_instance_profile" "ec2_private_profile" {
  name = "notes-ec2-private-profile"
  role = aws_iam_role.ec2_notes_private_role.name
}

### CodeArtifact access - lets pip authenticate against the pip mirror and
# pull packages, without any broader CodeArtifact or IAM permissions.
resource "aws_iam_role_policy" "codeartifact_access" {
  name = "codeartifact-pip-access"
  role = aws_iam_role.ec2_notes_private_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeartifact:GetAuthorizationToken",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ReadFromRepository"
        ]
        Resource = [
          aws_codeartifact_domain.lab_domain.arn,
          aws_codeartifact_repository.pip_mirror.arn
        ]
      },
      {
        # CodeArtifact auth tokens are minted through STS. Scoped so this
        # role can only get a bearer token for CodeArtifact - nothing else.
        Effect   = "Allow"
        Action   = "sts:GetServiceBearerToken"
        Resource = "*"
        Condition = {
          StringEquals = {
            "sts:AWSServiceName" = "codeartifact.amazonaws.com"
          }
        }
      }
    ]
  })
}
