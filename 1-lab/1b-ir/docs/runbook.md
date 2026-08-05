# Lab 1b — Incident Response Runbook
**Project:** AWS Portfolio — EC2/RDS Notes App Incident Response
**Application:** `http://<EC2_PUBLIC_IP>/`

---

## Pre-Incident Baseline

Confirm the application is healthy before injecting any failure.

```bash
curl http://<EC2_PUBLIC_IP>/init
curl http://<EC2_PUBLIC_IP>/add?note=first_note
curl http://<EC2_PUBLIC_IP>/add?note=sysbm_note
curl http://<EC2_PUBLIC_IP>/add?note=zoom2colombia_note
curl http://<EC2_PUBLIC_IP>/list
```

**Expected:** All notes returned, no errors.

📸 *Screenshot:  
<img width="440" height="44" alt="image" src="https://github.com/user-attachments/assets/fe43932f-d0c5-4436-9c1d-d892a695819e" />
<img width="580" height="44" alt="image" src="https://github.com/user-attachments/assets/fb22b386-b0b9-49bf-8335-f8d6a16037e2" />
<img width="580" height="43" alt="image" src="https://github.com/user-attachments/assets/fce3b752-84b9-4cb7-9b89-6e608f664c62" />
<img width="676" height="46" alt="image" src="https://github.com/user-attachments/assets/c86b1d04-f64b-4ea0-b54b-cd5bf79aa624" />
<img width="783" height="51" alt="image" src="https://github.com/user-attachments/assets/64b083c2-c4ef-483f-a3f1-7537c2889c2c" />

— terminal output showing successful `/init`, `/add`, and `/list` calls*

---

## Incident Injection (Auto-Grader Role)

Assume the incident-injector role:

```powershell
aws sts get-caller-identity
$creds = aws sts assume-role `
  --role-arn "arn:aws:iam::060214574171:role/lab-1b-incident-injector-role" `
  --role-session-name lab-1b-incident-injection | ConvertFrom-Json
$env:AWS_ACCESS_KEY_ID = $creds.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $creds.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $creds.Credentials.SessionToken
aws sts get-caller-identity
```

📸 *Screenshot:  
<img width="1393" height="484" alt="image" src="https://github.com/user-attachments/assets/2fd78764-a20e-4bff-a202-45575cf96547" />

 — `get-caller-identity` output confirming the assumed role*

Inject a random failure:

```powershell
$region = "us-east-1"
$secretId = "lab/rds/mysql/"
$dbInstanceId = "notes-db"

$rdsSecurityGroupId = "<RDS_SECURITY_GROUP_ID>"
$appSecurityGroupId = "<EC2_SECURITY_GROUP_ID>"

$incident = Get-Random -InputObject "secret-drift","network-isolation","db-interruption"

switch ($incident) {
    "secret-drift" {
        aws secretsmanager put-secret-value `
            --region $region `
            --secret-id $secretId `
            --secret-string '{\"username\":\"admin\",\"password\":\"wrong-lab-password\"}' | Out-Null
    }

    "network-isolation" {
        aws ec2 revoke-security-group-ingress `
            --region $region `
            --group-id $rdsSecurityGroupId `
            --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,UserIdGroupPairs=[{GroupId=$appSecurityGroupId}]" | Out-Null
    }

    "db-interruption" {
        aws rds stop-db-instance `
            --region $region `
            --db-instance-identifier $dbInstanceId | Out-Null
    }
}
```

**Note:** The incident type is intentionally not echoed to the console — the responder must diagnose it from logs and alarms, not from the injection script's output.

Trigger the failure against the running app:

```bash
curl http://<EC2_PUBLIC_IP>/list (X2)
```

📸 *Screenshot:  
<img width="1232" height="158" alt="image" src="https://github.com/user-attachments/assets/23035ff8-69a5-4581-8773-c20e38329978" />
— terminal output showing the app now returning a 500 error*

---

---

## SNS_Alert_Channel_SNS_Topic_Name

**CloudWatch Alarm → SNS Alarm**  
<img width="1228" height="730" alt="image" src="https://github.com/user-attachments/assets/c1f70bb7-e472-49fb-87a9-8c6429ed2f63" />  
**Expected:** Alarm transitions to ALARM SNS notification sent to email.
---

## Runbook Section 1 — Acknowledge

**1.1 Confirm Alert**

```bash
aws cloudwatch describe-alarms --alarm-names lab-db-auth-failure --query "MetricAlarms[].StateValue"
aws cloudwatch describe-alarms --alarm-names lab-db-network-failure --query "MetricAlarms[].StateValue"
aws cloudwatch describe-alarms --alarm-names lab-db-timeout-failure --query "MetricAlarms[].StateValue"
```

**Expected:** One of the three alarms shows `ALARM`.

📸 *Screenshot:  
<img width="1250" height="311" alt="image" src="https://github.com/user-attachments/assets/de52d109-d381-4f7c-8ee8-c1614623097c" />
— CLI output showing the fired alarm's state*

---

## Runbook Section 2 — Observe

**2.1 Check Application Logs**

```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"
```

**Expected:** Clear DB connection failure messages (`DB_AUTH_FAILURE`, `DB_CONNECTION_FAILURE`, or `DB_TIMEOUT_FAILURE`).

📸 *Screenshot:  
<img width="1580" height="600" alt="image" src="https://github.com/user-attachments/assets/d8ae6cb6-64d2-4f00-ad01-61bf4277a10e" /> 
 — filtered log output showing the classified error message*

**2.2 Identify Failure Type**

| Failure mode | Log signature | Behavior |
|---|---|---|
| Credential failure (secret drift) | `DB_AUTH_FAILURE` | Instant rejection — RDS actively responds "access denied" |
| DB stopped | `DB_UNKNOWN_FAILURE` / connection refused | Fails quickly — endpoint doesn't accept the connection |
| Network block (security group) | `DB_TIMEOUT_FAILURE` | Hangs, then times out — packet gets no response at all |

**Classification for this incident:** _______________________
**Reasoning:** _______________________

---

## Runbook Section 3 — Validate Configuration Sources

**3.1 Retrieve Parameter Store Values**

```bash
aws ssm get-parameters --names db_port_parameter --with-decryption
aws ssm get-parameters --names db_endpoint_parameter --with-decryption
aws ssm get-parameters --names db_name_parameter --with-decryption
```

**Expected:** Endpoint + port returned.

📸 *Screenshot:  
<img width="1060" height="1042" alt="image" src="https://github.com/user-attachments/assets/dd361699-0d0f-49fd-85ea-70a214c42c6c" />
**3.2 Retrieve Secrets Manager Values**

```bash
aws secretsmanager get-secret-value --secret-id lab/rds/mysql/
```

**Expected:** Username/password visible. Compare against known-good state.

📸 *Screenshot:  
<img width="1060" height="251" alt="image" src="https://github.com/user-attachments/assets/9d1ecce2-b1d5-4c0e-9086-782df8db83dc" />

---

## Runbook Section 4 — Containment

**4.1 Prevent Further Damage**

- Do not restart EC2 blindly
- Do not rotate secrets again
- Do not redeploy infrastructure

**Statement of containment:**
> "System state preserved for recovery."

📸 *Screenshot: `screenshots/troubleshooting/08-containment-statement.png` — optional: terminal/notes showing no destructive action taken*

---

## Runbook Section 5 — Recovery

Recovery path depends on the root cause identified in Section 2.2.

### 5.1 Credential Drift Recovery

**Option A** — restore Secrets Manager to the known-good password:
```bash
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql/ \
  --secret-string '{"username":"admin","password":"<KNOWN_GOOD_PASSWORD>"}'
```

**Option B** — update the RDS master password to match Secrets Manager:
```bash
aws rds modify-db-instance \
  --db-instance-identifier notes-db \
  --master-user-password '<PASSWORD_FROM_SECRETS_MANAGER>' \
  --apply-immediately
```

### 5.2 Network Block Recovery

```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sg_ec2_lab,private_sg" \
  --query "SecurityGroups[].{Name:GroupName,Id:GroupId}"

aws ec2 authorize-security-group-ingress \
  --group-id <RDS_SECURITY_GROUP_ID> \
  --protocol tcp \
  --port 3306 \
  --source-group <EC2_SECURITY_GROUP_ID>
```

### 5.3 DB Stopped Recovery

```bash
aws rds start-db-instance \
  --db-instance-identifier notes-db

aws rds wait db-instance-available \
  --db-instance-identifier notes-db
```

📸 *Screenshot:  
<img width="1060" height="251" alt="image" src="https://github.com/user-attachments/assets/7594f5ad-f8e8-421c-a3a3-64c6fe17f2ee" />  
— CLI output of recovery command

**Verify Recovery**

```bash
curl http://<EC2_PUBLIC_IP>/list
```

**Expected:** Application returns data, no errors.

📸 *Screenshot:  
<img width="714" height="44" alt="image" src="https://github.com/user-attachments/assets/9eb01b7f-7ab5-43e4-980c-47bf0167eaed" />

---

## Runbook Section 6 — Post-Incident Validation

**6.1 Confirm Alarm Clears**

```bash
curl http://<EC2_PUBLIC_IP>/list

aws cloudwatch describe-alarms --alarm-names lab-db-auth-failure --query "MetricAlarms[].StateValue"
aws cloudwatch describe-alarms --alarm-names lab-db-network-failure --query "MetricAlarms[].StateValue"
aws cloudwatch describe-alarms --alarm-names lab-db-timeout-failure --query "MetricAlarms[].StateValue"
```

**Expected:** `OK` (allow time for the next evaluation period after recovery).

📸 *Screenshot:  
<img width="1156" height="297" alt="image" src="https://github.com/user-attachments/assets/65c54878-33bb-403e-85e9-06c3b691a047" />  

**6.2 Confirm Logs Normalize**  
Why I changed the filter: the original --filter-pattern "ERROR" matches any log line at ERROR level — including unrelated internet scanning traffic hitting the public EC2 IP (malformed requests logged as code 400 errors), not just real database failures. That noise could produce a false "still seeing errors" reading even after the incident was fully resolved. Narrowing the filter to "DB_" matches only the application's own classified failure messages (DB_AUTH_FAILURE, DB_CONNECTION_FAILURE, DB_TIMEOUT_FAILURE), and adding --start-time scopes the check to only what happened after the recovery action — so an empty result set is a reliable confirmation that the fix worked, not just an artifact of what got filtered out.
```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"
 
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "DB_" \
  --start-time $(date -u -d "2026-08-04 19:48:00" +%s%3N)
```

**Expected:** No new errors after the recovery timestamp.


📸 *Screenshot:  
<img width="524" height="164" alt="image" src="https://github.com/user-attachments/assets/47fb66ae-c462-46a2-8bf5-f30e63d19691" />  
---

## Incident Summary

# Lab 1b — Incident Report
**Project:** AWS Portfolio — EC2/RDS Notes App Incident Response
**Date:** August 4, 2026

---

## Incident Summary

**What failed?**
Database authentication. The Secrets Manager secret (`lab/rds/mysql/`) was updated to an incorrect password without a corresponding update to the RDS master password, causing the application to be rejected by MySQL on every connection attempt (`Access denied for user 'admin'`).

**How was it detected?**
CloudWatch alarm `lab-db-auth-failure` transitioned to `ALARM` on the `DBAuthenticationFailures` metric, sourced from a CloudWatch Logs metric filter watching for classified `DB_AUTH_FAILURE` entries in the application log. Detection was confirmed directly on the EC2 instance via SSH:
```bash
sudo tail -20 /var/log/rdsapp.log
date -u
```
This surfaced the live application traceback — MySQL error code `1045` ("Access denied ... using password: YES") — a signature specific to credential rejection, distinct from a network timeout or an unavailable database. Comparing the log entry's timestamp against the `date -u` output confirmed the error was current (seconds old), not a stale entry from an earlier point in the investigation.

**Output:**

📸 *Screenshot: `screenshot of terminal output`*
```
[ec2-user@ip-10-90-1-151 ~]$ sudo tail -20 /var/log/rdsapp.log
date -u
  File "/opt/rdsapp/app.py", line 75, in get_conn
    return pymysql.connect(
  File "/usr/local/lib/python3.9/site-packages/pymysql/connections.py", line 372, in __init__
    self.connect()
  File "/usr/local/lib/python3.9/site-packages/pymysql/connections.py", line 702, in connect
    self._request_authentication()
  File "/usr/local/lib/python3.9/site-packages/pymysql/connections.py", line 1022, in _request_authentication
    auth_packet = _auth.caching_sha2_password_auth(self, auth_packet)
  File "/usr/local/lib/python3.9/site-packages/pymysql/_auth.py", line 258, in caching_sha2_password_auth
    return _roundtrip(conn, conn.password + b"\0")
  File "/usr/local/lib/python3.9/site-packages/pymysql/_auth.py", line 121, in _roundtrip
    pkt = conn._read_packet()
  File "/usr/local/lib/python3.9/site-packages/pymysql/connections.py", line 803, in _read_packet
    packet.raise_for_error()
  File "/usr/local/lib/python3.9/site-packages/pymysql/protocol.py", line 219, in raise_for_error
    err.raise_mysql_exception(self._data)
  File "/usr/local/lib/python3.9/site-packages/pymysql/err.py", line 154, in raise_mysql_exception
    raise errorclass(errno, errval, sqlstate=sqlstate)
pymysql.err.OperationalError: (1045, "Access denied for user 'admin'@'10.90.1.151' (using password: YES)")
2026-08-04 19:47:17,996 INFO 24.98.217.138 - - [04/Aug/2026 19:47:17] "GET /list HTTP/1.1" 500 -
Tue Aug  4 19:48:37 UTC 2026
```



**Root cause**
Credential drift between AWS Secrets Manager and the RDS instance's actual master password, introduced by the incident-injection script's `secret-drift` branch. Investigation initially considered a network-isolation cause due to an earlier connection-timeout signature in the logs, but direct verification (security group rules, RDS availability, endpoint configuration, and SG-to-instance attachment) ruled out every network-layer explanation, leaving credential drift as the confirmed root cause for the full duration of the outage.

**Time to recovery**
Approximately 2 hours from initial alarm to confirmed recovery. The extended duration reflects time spent verifying and ruling out network-layer causes before the credential mismatch was identified and corrected — not an inherent difficulty in the fix itself, which took under a minute to apply once the root cause was confirmed.

---

## Preventive Action

**To reduce MTTR:** Treat any "looks resolved" signal (a single successful request, an old log timestamp) as a hypothesis to re-verify immediately, not a conclusion — an early check during this incident was mistakenly read as self-resolution, which delayed identifying the actual ongoing cause.

**To prevent recurrence:** Extend the incident-injector/recovery IAM role to allow both `secretsmanager:PutSecretValue` and `rds:ModifyDBInstance`, so a responder can select the operationally correct recovery path for credential drift rather than being limited to whichever permission happens to be granted.
