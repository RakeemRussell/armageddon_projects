# Lab 1b Incident Response Runbook

Use this runbook when the EC2 to RDS Notes application is failing and the `lab-db-connection-failure` alarm fires.

Do not redeploy EC2, recreate RDS, or hardcode credentials. The goal is to observe, diagnose, and recover using CloudWatch Logs, CloudWatch Alarms, Parameter Store, Secrets Manager, and the existing AWS resources.

## Incident

Title: Database Connectivity Failure - Production Application Unavailable

Symptoms:

- `/list` fails, hangs, or returns an error.
- EC2 is still running.
- No recent code changes were announced.
- Users are reporting that the application is unavailable or unreliable.

Possible root causes:

- Credential drift: the password in Secrets Manager does not match the real RDS password.
- Network block: the RDS security group no longer allows MySQL traffic from the EC2 security group.
- DB interruption: the RDS instance is stopped or unavailable.

## Section 1 - Acknowledge

### 1.1 Confirm The Alarm

```sh
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

Line-by-line:

- `aws cloudwatch describe-alarms`: asks CloudWatch for alarm details.
- `--alarm-name lab-db-connection-failure`: limits the result to the database connection failure alarm for this lab.
- `--query "MetricAlarms[].StateValue"`: prints only the alarm state, such as `OK`, `ALARM`, or `INSUFFICIENT_DATA`.

Expected result:

```text
[
  "ALARM"
]
```

If the result is `ALARM`, acknowledge the incident and continue. If the result is `OK`, the failure may have recovered already, but continue checking logs before closing the incident.

## Section 2 - Observe

### 2.1 Check Application Error Logs

```sh
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"
```

Line-by-line:

- `aws logs filter-log-events`: searches CloudWatch Logs for matching log events.
- `--log-group-name /aws/ec2/lab-rds-app`: selects the log group where the EC2 Flask app writes its logs.
- `--filter-pattern "ERROR"`: returns only log events that contain the word `ERROR`.

Expected result:

- Log events showing database connection failures.
- The message should help identify whether the failure looks like credentials, networking, or database availability.

Common clues:

- `Access denied`: likely credential drift.
- `timed out` or `connection refused`: likely network block, RDS stopped, or RDS unavailable.
- `Unknown database`: likely DB name/configuration mismatch.

### 2.2 Classify The Failure

Write down one classification before touching anything:

```text
Failure classification: <Credential failure | Network failure | Database availability failure>
```

Explanation:

- This forces diagnosis before recovery.
- The lab grades whether you identified the failure type correctly.
- Do not restart EC2, rotate secrets, or redeploy infrastructure as a first response.

## Section 3 - Validate Configuration Sources

### 3.1 Retrieve Parameter Store Values

```sh
aws ssm get-parameters \
  --names db_endpoint_parameter db_port_parameter db_name_parameter \
  --with-decryption
```

Line-by-line:

- `aws ssm get-parameters`: retrieves multiple Systems Manager Parameter Store values.
- `--names db_endpoint_parameter db_port_parameter db_name_parameter`: asks for the stored RDS endpoint, port, and database name.
- `--with-decryption`: decrypts values if any of the parameters are stored as `SecureString`.

Expected result:

- `db_endpoint_parameter` returns the RDS hostname.
- `db_port_parameter` returns `3306`.
- `db_name_parameter` returns the application database name.

Use these values to confirm the app should be connecting to the correct database target.

### 3.2 Retrieve Secrets Manager Values

```sh
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```

Line-by-line:

- `aws secretsmanager get-secret-value`: retrieves the current secret value from Secrets Manager.
- `--secret-id lab/rds/mysql`: selects the lab database secret.

Expected result:

- A JSON secret string containing at least `username` and `password`.
- Depending on your implementation, it may also contain `host`, `port`, or database fields.

Use this to check whether the application is reading the expected credentials. Do not paste the password into reports or screenshots.

## Section 4 - Containment

State this before taking recovery action:

```text
System state preserved for recovery.
```

Explanation:

- Do not restart EC2 blindly.
- Do not rotate the secret again.
- Do not redeploy Terraform just to see what happens.
- The point is to preserve evidence, identify the root cause, and make the smallest correct fix.

## Section 5 - Recovery

Choose only the recovery path that matches your classification.

### 5.1 Credential Drift Recovery

Use this when logs show authentication failures such as `Access denied`.

Option A: update Secrets Manager back to the known-good database password.

```sh
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"<KNOWN_GOOD_PASSWORD>"}'
```

Line-by-line:

- `aws secretsmanager put-secret-value`: writes a new version of the secret.
- `--secret-id lab/rds/mysql`: updates the lab database secret.
- `--secret-string ...`: stores the JSON credential payload that the app reads.

Option B: update the RDS master password to match Secrets Manager.

```sh
aws rds modify-db-instance \
  --db-instance-identifier notes-db \
  --master-user-password '<PASSWORD_FROM_SECRETS_MANAGER>' \
  --apply-immediately
```

Line-by-line:

- `aws rds modify-db-instance`: changes settings on an existing RDS instance.
- `--db-instance-identifier notes-db`: selects the lab RDS instance.
- `--master-user-password '<PASSWORD_FROM_SECRETS_MANAGER>'`: sets the actual database password to match the stored secret.
- `--apply-immediately`: applies the change now instead of waiting for the maintenance window.

### 5.2 Network Block Recovery

Use this when logs show timeouts and the RDS inbound rule is missing EC2 security group access.

First, identify the security group IDs:

```sh
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sg_ec2_lab,private_sg" \
  --query "SecurityGroups[].{Name:GroupName,Id:GroupId}"
```

Line-by-line:

- `aws ec2 describe-security-groups`: reads security group configuration.
- `--filters "Name=group-name,Values=sg_ec2_lab,private_sg"`: returns only the EC2 and RDS lab security groups.
- `--query "SecurityGroups[].{Name:GroupName,Id:GroupId}"`: prints just the group names and IDs.

Then restore MySQL access from EC2 to RDS:

```sh
aws ec2 authorize-security-group-ingress \
  --group-id <RDS_SECURITY_GROUP_ID> \
  --protocol tcp \
  --port 3306 \
  --source-group <EC2_SECURITY_GROUP_ID>
```

Line-by-line:

- `aws ec2 authorize-security-group-ingress`: adds an inbound rule to a security group.
- `--group-id <RDS_SECURITY_GROUP_ID>`: chooses the RDS/private security group to fix.
- `--protocol tcp`: uses TCP, which MySQL requires.
- `--port 3306`: opens only the MySQL port.
- `--source-group <EC2_SECURITY_GROUP_ID>`: allows traffic only from the EC2 app security group, not from the public internet.

### 5.3 DB Stopped Recovery

Use this when RDS is stopped or not available.

```sh
aws rds start-db-instance \
  --db-instance-identifier notes-db
```

Line-by-line:

- `aws rds start-db-instance`: starts a stopped RDS database instance.
- `--db-instance-identifier notes-db`: selects the lab RDS instance.

Wait until RDS is available:

```sh
aws rds wait db-instance-available \
  --db-instance-identifier notes-db
```

Line-by-line:

- `aws rds wait db-instance-available`: pauses until AWS reports the DB instance is available.
- `--db-instance-identifier notes-db`: waits on the lab RDS instance.

## Section 6 - Verify Recovery

### 6.1 Test The Application

```sh
curl http://<EC2_PUBLIC_IP>/list
```

Line-by-line:

- `curl`: sends an HTTP request from the command line.
- `http://<EC2_PUBLIC_IP>/list`: calls the app endpoint that reads notes from RDS.

Expected result:

- The application returns the notes list.
- The request does not hang.
- The request does not return a database error.

### 6.2 Confirm Alarm Clears

```sh
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

Line-by-line:

- `aws cloudwatch describe-alarms`: reads CloudWatch alarm details.
- `--alarm-name lab-db-connection-failure`: checks the lab database alarm.
- `--query "MetricAlarms[].StateValue"`: prints only the current state.

Expected result:

```text
[
  "OK"
]
```

The alarm may take several minutes to return to `OK` because the metric period is 5 minutes.

### 6.3 Confirm Logs Normalize

```sh
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"
```

Line-by-line:

- `aws logs filter-log-events`: searches CloudWatch Logs again.
- `--log-group-name /aws/ec2/lab-rds-app`: checks the application log group.
- `--filter-pattern "ERROR"`: looks for error entries.

Expected result:

- No new database connection errors after the recovery time.
- Older errors may still appear because CloudWatch Logs keeps historical events.

## Section 7 - Required Incident Report

Fill this out after recovery:

```text
Incident Summary:

What failed:

How it was detected:

Root cause:

Failure classification:

Recovery action taken:

Time to recovery:

Preventive action to reduce MTTR:

Preventive action to prevent recurrence:
```

## Section 8 - Grading Checklist

- Alarm acknowledged via CLI.
- Logs checked before recovery.
- Failure type classified correctly.
- Parameter Store values validated.
- Secrets Manager values validated.
- Correct recovery action used.
- No redeploy, no guessing, no hardcoded credentials.
- Clear incident summary submitted.

## runbook

*******************************************************************************************
*******************************************************************************************
Create an intentional failure with assistant acting as the group leader or auto-grader:
$creds = aws sts assume-role --role-arn "arn:aws:iam::060214574171:role/lab-1b-incident-injector-role" --role-session-name lab-1b-incident-injection | ConvertFrom-Json
$env:AWS_ACCESS_KEY_ID = $creds.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $creds.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $creds.Credentials.SessionToken
aws sts get-caller-identity

# ----- Lab values you must fill in -----
$region = "us-east-1"
$secretId = "lab/rds/mysql"
$dbInstanceId = "notes-db"
$rdsSecurityGroupId = "sg-xxxxxxxxxxxxxxxxx"
$mysqlSourceCidr = "10.0.0.0/16"
$mysqlPort = 3306

# ----- Randomly choose exactly one incident -----
$incident = Get-Random -InputObject "secret-drift","network-isolation","db-interruption"

# Optional: show only to injector/group leader, not student
Write-Host "Selected incident: $incident"

# ----- Inject the selected incident -----
switch ($incident) {
    "secret-drift" {
        Write-Host "Injecting secret drift..."

        aws secretsmanager put-secret-value `
            --region $region `
            --secret-id $secretId `
            --secret-string '{"username":"admin","password":"wrong-lab-password"}'
    }

    "network-isolation" {
        Write-Host "Injecting network isolation..."

        aws ec2 revoke-security-group-ingress `
            --region $region `
            --group-id $rdsSecurityGroupId `
            --protocol tcp `
            --port $mysqlPort `
            --cidr $mysqlSourceCidr
    }

    "db-interruption" {
        Write-Host "Injecting DB interruption..."

        aws rds stop-db-instance `
            --region $region `
            --db-instance-identifier $dbInstanceId
    }
}

$appSecurityGroupId = "sg-yyyyyyyyyyyyyyyyy"

aws ec2 revoke-security-group-ingress `
    --region $region `
    --group-id $rdsSecurityGroupId `
    --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,UserIdGroupPairs=[{GroupId=$appSecurityGroupId}]"

Write-Host "Incident injected. Start the runbook."
*******************************************************************************************
*******************************************************************************************
Trigger the failure:
curl <http://3.95.171.199/list> (x2)

1.1 Confirm The Alarm and 7.6 Verify CloudWatch Alarm
aws cloudwatch describe-alarms  --alarm-name-prefix db_alarm_aws
aws cloudwatch describe-alarms  --alarm-name lab-db-connection-failure  --query "MetricAlarms[].StateValue"

2.1 Check Application Error Logs or 7.5 Verify CloudWatch received it
aws logs filter-log-events  --log-group-name /aws/ec2/lab-rds-app  --filter-pattern "ERROR"

3.1 Retrieve Parameter Store Values and 7.7 Incident Recovery Verification After restoring correct credentials or connectivity
aws ssm get-parameters  --names db_endpoint_parameter db_port_parameter db_name_parameter  --with-decryption

3.2 Retrieve Secrets Manager Values or 7.2 Verify Secrets Manager Value
  aws secretsmanager get-secret-value  --secret-id lab/rds/mysql/

Section 5 - Recovery

5.1 Credential Drift Recovery

Option A: update Secrets Manager back to the known-good database password.
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"<KNOWN_GOOD_PASSWORD>"}'

Option B: update the RDS master password to match Secrets Manager
aws rds modify-db-instance \
  --db-instance-identifier notes-db \
  --master-user-password '<PASSWORD_FROM_SECRETS_MANAGER>' \
  --apply-immediately

5.2 Network Block Recovery

aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sg_ec2_lab,private_sg" \
  --query "SecurityGroups[].{Name:GroupName,Id:GroupId}"

aws ec2 authorize-security-group-ingress \
  --group-id <RDS_SECURITY_GROUP_ID> \
  --protocol tcp \
  --port 3306 \
  --source-group <EC2_SECURITY_GROUP_ID>

5.3 DB Stopped Recovery

aws rds start-db-instance \
  --db-instance-identifier notes-db

aws rds wait db-instance-available \
  --db-instance-identifier notes-db

Section 6 - Verify Recovery

curl http://<EC2_PUBLIC_IP>/list

6.2 Confirm Alarm Clears
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"

6.3 Confirm Logs Normalize
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"

$creds = aws sts assume-role --role-arn "arn:aws:iam::060214574171:user/AWSCLI" --role-session-name lab-1b-incident-injection | ConvertFrom-Json
$env:AWS_ACCESS_KEY_ID = $creds.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $creds.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $creds.Credentials.SessionToken
aws sts get-caller-identity
