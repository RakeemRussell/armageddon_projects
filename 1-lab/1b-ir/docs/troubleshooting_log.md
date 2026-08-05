# Lab 1b — Incident Response: Troubleshooting Log
**Project:** AWS Portfolio — EC2/RDS Notes App Incident Response
**Date:** August 4, 2026

---

## Summary

An auto-grader role injected a failure into the application's database connectivity. The application was unreachable (`/list` returning HTTP 500) from initial detection until the root cause was corrected via Secrets Manager. During investigation, the error signature in the logs changed from a connection timeout to an explicit authentication rejection, which initially suggested two separate problems. Systematic verification ruled out every network-layer cause (security group rules, RDS availability, endpoint configuration all confirmed correct), leaving credential drift as the only remaining explanation for the entire outage window. The application was not retested against live traffic during the network-layer investigation — only after the fact, once the credential fix was applied — so the outage should be treated as continuous rather than resolved-and-recurring.

---

## Investigation Timeline

### Initial Detection

CloudWatch alarm `lab-db-timeout-failure` transitioned to `ALARM`. Application logs showed:
```
pymysql.err.OperationalError: (2003, "Can't connect to MySQL server on 'notes-db...' (timed out)")
```

### Hypothesis: Network Isolation

A connection timeout — as opposed to an instant rejection — is the expected signature of a blocked network path: a TCP packet sent with no response at all, rather than an active refusal. This pointed toward a revoked security group rule (the `network-isolation` injection type).

### Verification (Section 3 — Validate Configuration Sources)

Each layer was checked directly against live AWS state rather than acting on the hypothesis alone:

| Check | Command | Result |
|---|---|---|
| RDS security group rule presence | `aws ec2 describe-security-groups --group-ids <rds_sg>` | Rule present, allowing TCP 3306 from `sg-01a8bf704d3168eb8` |
| RDS instance status | `aws rds describe-db-instances --query "DBInstances[0].DBInstanceStatus"` | `available` |
| Parameter Store endpoint vs. actual RDS endpoint | `aws ssm get-parameter --name db_endpoint_parameter` vs. `aws rds describe-db-instances --query "...Endpoint.Address"` | Exact match |
| EC2's actual attached security group | `aws ec2 describe-instances --query "...SecurityGroups"` | `sg-01a8bf704d3168eb8` — matches the SG the RDS rule permits |

Every network-layer check came back clean: no misconfiguration existed at the security group, RDS availability, or endpoint/DNS level. This ruled out `network-isolation` and `db-interruption` as the active root cause.

**Note on this step:** a `curl` check at this point in the investigation returned successfully, and the log timestamp of the timeout error was compared against system time, showing a gap of roughly 90 minutes. This was initially read as the incident having self-resolved. That conclusion was incorrect — no destructive or corrective action (no `terraform destroy`, no manual fix) had been taken at that point, and the application in fact remained unreachable under real use until the credential fix was applied later. The successful `curl` should not have been treated as proof of resolution without immediately re-confirming with a fresh, repeated test — a single successful request is not sufficient to conclude an intermittent or credential-based failure has cleared, since some request paths may succeed transiently or via cached connections while others continue to fail.

### Direct Log Inspection — How the Real Root Cause Was Found

Rather than continuing to rely on filtered CloudWatch queries, the application log was read directly on the EC2 instance via SSH, alongside a current-time check to confirm freshness:

```bash
sudo tail -20 /var/log/rdsapp.log
date -u
```

**Output:**
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

📸 *Screenshot: `screenshots/troubleshooting/13-log-check-detection.png` — terminal output shown above*

Pairing `tail` with `date -u` was deliberate: the log entry's timestamp (`19:47:17`) fell only 80 seconds before the current system time (`19:48:37`), confirming this was a live, current failure rather than a stale entry left over from the earlier timeout investigation — the same mistake made a step earlier when a resolved-looking timestamp was assumed without a fresh recheck.

### Classification (Section 2.2)

MySQL error code `1045` with `"Access denied for user 'admin'@'10.90.1.151' (using password: YES)"` is an unambiguous credential-failure signature: the connection reached RDS successfully and was actively rejected due to incorrect authentication — distinct from the earlier timeout signature (no response at all) and distinct from an availability failure (endpoint refusing or failing to resolve the connection outright).

**Classification: Credential Drift (Secret Drift)**

Since network-layer causes had already been fully ruled out by direct verification, and the application had not been confirmed genuinely healthy at any point after the original timeout was first observed, the most defensible conclusion is that credential drift was the root cause for the full duration of the outage — not a second, independent incident layered on top of a resolved one. The initial timeout signature may have reflected a transient connection-attempt state during the same underlying credential failure, rather than a distinct network event. This was not conclusively isolated during the investigation and is noted here as an open question rather than asserted as fact.

### Verification (Section 3, repeated)

```bash
aws secretsmanager get-secret-value --secret-id lab/rds/mysql/
```
Confirmed the password stored in Secrets Manager did not match the value RDS currently accepted, consistent with the injector's `secret-drift` branch having modified the secret without updating RDS itself.

### Containment (Section 4)

No EC2 restart, no additional secret rotation, and no infrastructure redeployment was performed while root cause was being confirmed. System state was preserved for recovery.

### Recovery (Section 5.1, Option A)

Restored Secrets Manager to the known-good credential value:
```bash
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql/ \
  --secret-string '{"username":"admin","password":"password123"}'
```

Option A (updating Secrets Manager back to match RDS) was used rather than Option B (updating RDS's master password to match the drifted secret), since the injector role's IAM permissions at the time granted `secretsmanager:PutSecretValue` but not `rds:ModifyDBInstance`.

### Verification of Recovery

```bash
curl http://<EC2_PUBLIC_IP>/list
```
Application returned data successfully with no errors, confirmed by repeated requests rather than a single call.

### Post-Incident Validation (Section 6)

**Alarm state:**
```bash
aws cloudwatch describe-alarms --alarm-names lab-db-auth-failure --query "MetricAlarms[].StateValue"
```
Alarm returned to `OK` on its next evaluation cycle.

**Log normalization — narrowed query:**

The initial log-check approach (`--filter-pattern "ERROR"`) was refined after noticing it also matches unrelated internet scanning traffic hitting the public EC2 IP (malformed requests logged at ERROR level as `code 400` responses) — not just genuine database failures. This could produce a false "still seeing errors" reading even after the incident was fully resolved. The filter was narrowed to match only the application's own classified failure messages, and scoped to only the time after recovery:

```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "DB_" \
  --start-time $(date -u -d "2026-08-04 19:48:00" +%s%3N)
```

**Output:**
```json
{
    "events": [],
    "searchedLogStreams": []
}
```

An empty result set confirmed no further `DB_AUTH_FAILURE`, `DB_CONNECTION_FAILURE`, or `DB_TIMEOUT_FAILURE` entries occurred after recovery — a reliable confirmation, since it excludes the scanner noise that a plain `"ERROR"` filter would have included.

📸 *Screenshot: `screenshots/troubleshooting/12-logs-normalized.png` — terminal output shown above*

---

## Incident Summary

| Field | Value |
|---|---|
| What failed | Database authentication — Secrets Manager credential drift |
| How was it detected | CloudWatch alarm `lab-db-auth-failure` transition to `ALARM`, confirmed by direct SSH inspection of `/var/log/rdsapp.log` (`sudo tail -20` paired with `date -u` to confirm the error was live, not stale) |
| Root cause | Secrets Manager password updated by the injected incident without a corresponding update to the RDS master password; the application remained unreachable for the entire investigation window until this was corrected |
| Time to recovery | Approximately 2 hours from initial alarm to confirmed recovery — extended by time spent investigating and ruling out network-layer causes before the credential mismatch was identified as the actual, ongoing root cause |

---

## Lessons Learned

**On confirming recovery, not just plausibility:**
A single successful request during an active investigation is not sufficient evidence that an incident has resolved. This investigation initially treated one successful `curl` call, combined with an old log timestamp, as proof of self-resolution — but no corrective action had actually occurred, and the application was later confirmed to still be failing under real use. Recovery should be confirmed with repeated, real-time verification at the moment a fix is applied, not inferred from an earlier data point. Pairing `tail` with `date -u` during direct log inspection is what ultimately caught this — comparing a log entry's timestamp against the current time is a simple, repeatable way to confirm freshness rather than assuming it.

**On symptom-based classification:**
A timeout signature is consistent with a network block but is not exclusive to it. Ruling out every network-layer cause through direct verification (security group rules, RDS status, endpoint configuration, SG-to-instance attachment) was the correct process and is what ultimately pointed the investigation toward the real, ongoing root cause — credential drift — rather than a network issue that didn't actually exist.

**On log filter precision:**
A broad `--filter-pattern "ERROR"` query captures unrelated noise (in this case, internet background scanning traffic against the public EC2 IP) alongside genuine application failures. Post-incident validation should filter specifically for the application's own classified error codes and scope to the time window after recovery, or a clean result can be indistinguishable from a masked one.

**On IAM scoping during incident response:**
The recovery path actually available (Option A) was determined by the injector role's IAM permissions at the time, not by which recovery approach was theoretically preferable. Incident responders need to know their actual permission boundaries before committing to a recovery plan.

**On public endpoint exposure:**
Application logs during this investigation also showed unsolicited scanning traffic from unrelated external IPs, probing malformed requests and common paths (`/version`, `/v1`). This is expected for any publicly reachable EC2 instance and is not evidence of compromise, but reinforces that a production-equivalent version of this architecture should sit behind a load balancer/WAF rather than exposing the application host directly.

**Preventive actions:**
- To reduce MTTR: treat any "looks resolved" signal (a single successful test, an old log timestamp) as a hypothesis requiring immediate re-verification, not a conclusion — pair log checks with a current-time comparison (`tail` + `date -u`) as a standard habit, not an afterthought.
- To prevent recurrence: extend IAM permissions granted to the incident-injector/recovery role to cover both recovery options (`secretsmanager:PutSecretValue` and `rds:ModifyDBInstance`) so the responder can choose the operationally correct recovery path rather than the only permitted one.