resource "aws_iam_role" "auto_grader" {
  name = "lab-1b-incident-injector-role"

  assume_role_policy = data.aws_iam_policy_document.incident_injector_trust_policy.json

  tags = {
    Name        = "lab-1b-incident-injector-role"
    Environment = "lab_ir"
    Purpose     = "Temporary incident injection for Lab 1b"
  }
}

data "aws_iam_policy_document" "incident_injector_trust_policy" {
  statement {
    sid    = "AllowTrustedPrincipalToAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"
      identifiers = [
        var.iam_role_auto_grader_arn
      ]
    }
  }
}

resource "aws_iam_policy" "incident_injector_policy" {
  name        = "lab-1b-incident-injector-policy"
  description = "Least-privilege permissions to inject and recover Lab 1b incidents."

  policy = data.aws_iam_policy_document.incident_injector_policy.json
}

data "aws_iam_policy_document" "incident_injector_policy" {
  statement {
    sid    = "ReadLabState"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "rds:DescribeDBInstances",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowCredentialRecoveryOnLabDatabase"
    effect = "Allow"

    actions = [
      "rds:ModifyDBInstance"
    ]

    resources = [
      aws_db_instance.mysql_rds_db.arn
    ]
  }

  statement {
    sid    = "AllowSecretDriftOnlyOnLabSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:PutSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.db_secret.arn
    ]
  }

  statement {
    sid    = "AllowNetworkIncidentOnlyOnLabRdsSecurityGroup"
    effect = "Allow"

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]

    resources = [
      aws_security_group.sg_private_resource.arn
    ]
  }

  statement {
    sid    = "AllowDbInterruptionOnlyOnLabDatabase"
    effect = "Allow"

    actions = [
      "rds:StartDBInstance",
      "rds:StopDBInstance"
    ]

    resources = [
      aws_db_instance.mysql_rds_db.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "incident_injector_policy_attachment" {
  role       = aws_iam_role.auto_grader.name
  policy_arn = aws_iam_policy.incident_injector_policy.arn
}
