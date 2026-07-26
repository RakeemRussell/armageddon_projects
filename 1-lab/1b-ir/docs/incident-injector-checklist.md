# Lab 1b Incident Injector Checklist

Use this checklist when the assistant acts as the group leader or auto-grader. The injector role does not use access keys. It is assumed temporarily with AWS STS.

## One-Time Terraform Setup

- Confirm the normal Lab 1b infrastructure works.
- Confirm `/list` returns notes before injecting an incident.
- Confirm the CloudWatch log group exists: `/aws/ec2/lab-rds-app`.
- Confirm the CloudWatch alarm exists: `lab-db-connection-failure`.
- Confirm the SNS email subscription is confirmed.
- Set `email_alert` in `terraform.tfvars`.
- Set `incident_injector_trusted_principal_arn` in `terraform.tfvars` to the IAM user or role ARN that is allowed to assume the injector role.
- Run `terraform fmt`.
- Run `terraform validate`.
- Run `terraform plan`.
- Run `terraform apply`.
- Save the `incident_injector_role_arn` output.

## How To Find Your Trusted Principal ARN

Run this with your normal AWS credentials:

```sh
aws sts get-caller-identity
```

Line-by-line:

- `aws sts get-caller-identity`: asks AWS who the current credentials belong to.

Use the returned `Arn` value as `incident_injector_trusted_principal_arn`.

Example `terraform.tfvars`:

```hcl
email_alert = "you@example.com"

incident_injector_trusted_principal_arn = "arn:aws:iam::123456789012:user/your-user"
```

## Temporary Role Assumption

When it is time to inject an incident, assume the role:

```sh
aws sts assume-role \
  --role-arn <INCIDENT_INJECTOR_ROLE_ARN> \
  --role-session-name lab-1b-incident-injection
```

Line-by-line:

- `aws sts assume-role`: requests temporary credentials for an IAM role.
- `--role-arn <INCIDENT_INJECTOR_ROLE_ARN>`: selects the limited incident injector role.
- `--role-session-name lab-1b-incident-injection`: labels the temporary session in AWS logs.

The returned credentials expire. Do not create IAM access keys.

## Random Incident Selection

The assistant should randomly select exactly one incident:

```powershell
$incident = Get-Random -InputObject "secret-drift","network-isolation","db-interruption"
```

Line-by-line:

- `$incident =`: stores the selected incident in a PowerShell variable.
- `Get-Random`: randomly chooses one item.
- `-InputObject "secret-drift","network-isolation","db-interruption"`: limits the choice to the three approved lab incidents.

The selected incident must not be revealed to the student until after diagnosis.

## Allowed Incident Injections

Secret drift:

- Change only the `lab/rds/mysql` secret value.
- Do not update the real RDS password.

Network isolation:

- Remove only the MySQL inbound rule on the RDS/private security group.
- Do not change public EC2 HTTP access.

DB interruption:

- Stop only the `notes-db` RDS instance.
- Do not delete, recreate, or modify storage.

## Student Prompt

After injection, say only:

```text
Incident injected. Start the runbook.
```

## Grading

- Student acknowledges the alarm through CLI.
- Student checks logs before recovery.
- Student validates Parameter Store values.
- Student validates Secrets Manager values.
- Student classifies the failure correctly.
- Student chooses the correct recovery path.
- Student avoids redeploying infrastructure.
- Student verifies recovery with `/list`.
- Student confirms alarm state returns to `OK`.

## Cleanup

- Recover the injected failure.
- Confirm `/list` works.
- Confirm no new app errors are appearing.
- Confirm the alarm returns to `OK`.
- Keep the role if more blind tests are needed.
- Remove the role with Terraform when the lab is complete.
