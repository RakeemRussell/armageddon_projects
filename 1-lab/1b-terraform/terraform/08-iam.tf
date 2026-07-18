### Creates the IAM Role (an identity a AWS resource can assume)
resource "aws_iam_role" "ec2_notes_role" {

  name = "ec2-notes-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

### Creates the IAM Trust Policy, that defines which AWS service can use this role and needs to be attached to a IAM Role
data "aws_iam_policy_document" "ec2_assume_role" {

  statement {

    actions = ["sts:AssumeRole"]

    principals {

      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

### IAM Policy (contains permissions, just as a wallet holds a license)
resource "aws_iam_policy" "ec2_secrets_policy" {

  name = "ec2-read-rds-secret"

  policy = data.aws_iam_policy_document.ec2_secrets_policy.json
}

### Creates Permissions for the IAM Role, that defines what the role can do, this needs to be attached to a IAM Policy 
data "aws_iam_policy_document" "ec2_secrets_policy" {

  statement {

    actions = [
      "secretsmanager:GetSecretValue",

    ]

    resources = [
      
      
      aws_secretsmanager_secret.db_secret.arn
    ]
  }
    statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]

    resources = [
      aws_ssm_parameter.db_endpoint.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_name.arn
    ]
  }
}

### Attaches the Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "attach_secret_policy" {

  role = aws_iam_role.ec2_notes_role.name

  policy_arn = aws_iam_policy.ec2_secrets_policy.arn
}

### Creates an Instance Profile for the EC2 IAM Role(same as a wallet for a license, with the license being a IAM Role with a policy attached)
resource "aws_iam_instance_profile" "ec2_profile" {

  name = "notes-ec2-profile"

  role = aws_iam_role.ec2_notes_role.name
}