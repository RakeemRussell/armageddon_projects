# Trouble Shooting Log

## Error: 1

 Missing required provider

> Problem:
Forgot to run terraform init  

![Missing required provider](screenshots/sc_1.png)

> Solution:
Ran terraform init then terraform validate  

![Missing required provider](screenshots/sc_2.png)

![Missing required provider](screenshots/sc_3.png)

---

---

## Error: 2

 creating SSM Parameter (db/endpoint/parameter): operation error SSM: PutParameter, https response error StatusCode: 400, RequestID: a518e1c0-42ec-4a02-8c9c-42a5b41f4bfa, api error ValidationException: Parameter name must be a fully qualified name

> Problem:

![unqualified name](screenshots/sc_7.png)

> Solution:

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: 3

 creating SSM Parameter (db/port/parameter): operation error SSM: PutParameter, https response error StatusCode: 400, RequestID: bb6a57a2-ce20-4481-8ef4-c8b8f116fcaa, api error ValidationException: Parameter name must be a fully qualified name

> Problem:

![unqualified name](screenshots/sc_8.png)

> Solution:

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: 4

 creating SSM Parameter (db/name/parameter): operation error SSM: PutParameter, https response error StatusCode: 400, RequestID: 46e5caa0-1e0c-469a-8263-99010f93a51b, api error ValidationException: Parameter name must be a fully qualified name

> Problem:

![unqualified name](screenshots/sc_0.png)

> Solution:

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: 5

[ec2-user@ip-10-90-1-50 ~]$ aws ssm get-parameters \
  --names db_endpoint_parameter db_port_parameter db_name_parameter

An error occurred (AccessDeniedException) when calling the GetParameters operation: User: arn:aws:sts::060214574171:assumed-role/ec2-notes-role/i-039a9c9d71f03d559 is not authorized to perform: ssm:GetParameters on resource: arn:aws:ssm:us-east-1:060214574171:parameter/db_endpoint_parameter because no identity-based policy allows the ssm:GetParameters action
[ec2-user@ip-10-90-1-50 ~]$  

> Problem:
missing "ssm:GetParameters" in file 11, under actions in  "aws_iam_policy_document" "ec2_secrets_policy"  

![Missing required provider](screenshots/sc_11.png)
![Missing required provider](screenshots/sc_12.png)

---
> Solution: added ssm:getparameters

![Missing required provider](screenshots/sc_13.png)  
![Missing required provider](screenshots/sc_14.png)  

---

---

## Error: 6

conflicting configuration arguments

> Problem:

![Missing required provider](screenshots/sc_15.png)

> Solution:
deleted manage_master_user_password = false from file 6

![Missing required provider](screenshots/sc_16.png)

---

---

## Error: 7

Invalid index

> Problem:

![Missing required provider](screenshots/sc_17.png)
![Missing required provider](screenshots/sc_18.png)

> Solution:

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: 8

creating Secrets Manager Secret (lab_rds_mysql): operation error Secrets Manager: CreateSecret, https response error StatusCode: 400, RequestID: a815106c-649a-4f4a-8a3e-600f0aace6dc, InvalidRequestException: You can't create this secret because a secret with this name is already scheduled for deletion

> Problem:
lab_rds_mysql secret was scheduled for deletion after running terraform destroy

![Missing required provider](screenshots/sc_19.png)

> Solution:

restore the secret

![Missing required provider](screenshots/sc_20.png)
![Missing required provider](screenshots/sc_21.png)

---

---

## Error: 10

creating Secrets Manager Secret (lab_rds_mysql): operation error Secrets Manager: CreateSecret, https response error StatusCode: 400, RequestID: 70c6d784-0a65-412d-a6e3-471a00dd91af, ResourceExistsException: The operation failed because the secret lab_rds_mysql already exists.

> Problem:

lab_rds_mysql secret already exists

![Missing required provider](screenshots/sc_22.png)

> Solution:

Rename the secret to lab/rds/mysql

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: 11

aws: [ERROR]: An error occurred (ParameterNotFound) when calling the GetParameter operation:

> Problem:

miss matched names

![Missing required provider](screenshots/sc_23.png)

> Solution:
changed from aws "ssm get-parameter --name /lab/db/endpoint" to "aws ssm get-parameter --name db_endpoint_parameter"

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: ---

> Problem:

![Missing required provider](screenshots/sc_0.png)

> Solution:

![Missing required provider](screenshots/sc_0.png)

---

---

## Error: ---

> Problem:

![Missing required provider](screenshots/sc_0.png)

> Solution:

![Missing required provider](screenshots/sc_0.png)

---
