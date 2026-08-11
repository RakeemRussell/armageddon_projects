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