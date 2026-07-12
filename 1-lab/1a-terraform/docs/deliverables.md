# Deliverables

1.
    - Screenshot of: RDS SG inbound rule using source = sg-ec2-lab
    ![rds_console](../screenshots/rds/deliverable-rds.png)

    - Screenshot of: EC2 role attached
    ![ec2_console](../screenshots/iam/deliverable-ec2_role.png)
    - Screenshot(2) of: EC2 role attached
    ![alt text](../screenshots/iam/deliverable-ec2_role(2).png)

    - Screenshot of: /list output showing at least 3 notes  
    ![end_point](../screenshots/endpoint/deliverable-list_output.png)

2.  
    a) Why is DB inbound source restricted to the EC2 security group?  
        so that only the application server can connect to the database  

    b) What port does MySQL use?  
        MySQL uses TCP port 3306  

    c) Why is Secrets Manager better than storing creds in code/user-data?  
        because credentials are encrypted, can be rotated automatically, and are not exposed in repositories, EC2 metadata, or configuration files

3. Evidence for Audits / Labs (CLI Outputs)  
    - aws ec2 describe-security-groups  
    ![sg-cli-output](../screenshots/security-groups/deliverable-sg_cli_output.png)
    - aws rds describe-db-instances  
    ![rds-cli-output](../screenshots/rds/deliverable-rds_cli_output.png)
    - aws secretsmanager describe-secret
    ![sm-cli-output](../screenshots/secrets-manager/deliverable-secrets_manager_secret.png)
    - aws ec2 describe-instances
    ![ec2-cli-output](../screenshots/ec2/deliverable-instance_cli_output.png)
    - aws iam list-attached-role-policies
    ![role-cli-output](../screenshots/iam/deliverable-ec2_cli_output.png)

Then Answer: Response  

1. Why each rule exists  
2. What would break if removed  
3. Why broader access is forbidden  
4. Why this role exists  
5. Why it can read this secret  
6. Why it cannot read others

```s
Public Subnet  

    1. Why each rule exists  
subnet resources do not create permissions,they define the network layout, this public subnet exist because the database should never be directly reachable from the internet and only the EC2 application should communicate with it

    2. What would break if removed  
the ec2 instance would have nowhere to be deployed, without the public subnet the ec2 could not exist inside the VPC

    3. Why broader access is forbidden  
following principle of least privilege, not placing databases onto public networks decreases attack surface

    4. Why this role exists
subnet resources do not grant identities or permissions, no IAM Role is created here

    5. Why it can read this secret  
Subnets cannot read Secrets Manager, only an IAM Role with the appropriate policy can

    6. Why it cannot read others  
IAM policies determine which secrets can be accessed, subnets can not make API calls
```

```s
Private Subnets  

    1. Why each rule exists  
subnet resources do not create permissions,they define the network layout, these private subnets exist because Amazon RDS requires a DB Subnet Group containing subnets in at least two Availability Zones, even if using a Single-AZ database AWS still requires subnet groups that span multiple AZs

    2. What would break if removed  
AWS would reject the build with an error, if a database was running in the subnet that was removed, it would become unreachable because it no longer has a network interface, the ec2 application would fail to connect to MySQL throwing connection errors.

    3. Why broader access is forbidden  
following principle of least privilege, placing databases onto private networks decreases attack surface, this subnet should remain private because it is reserved for backend infrastructure resources that should not have direct Internet access

    4. Why this role exists
subnet resources do not grant identities or permissions, no IAM Role is created here

    5. Why it can read this secret  
Subnets cannot read Secrets Manager, only an IAM Role with the appropriate policy can

    6. Why it cannot read others  
IAM policies determine which secrets can be accessed, subnets can not make API calls
```

```s
Internet Gateway

    1. Why each rule exists  
Internet Gateway resources do not create permissions. the Internet Gateway provides a path between the VPC and the public internet, so resources can send or receive internet traffic

    2. What would break if removed  
access to the website would fail, SSH and HTTP request from anywhere would fail. EC2 instance would no longer be able to install packages using dnf, download Python libraries using pip or download any updates. public route to the internet gateway would fail.

    3. Why broader access is forbidden  
Internet Gateway does not grant permissions, it does not authenticate users, authorize requests or filter traffic, it only forwards packets according to the VPC routing configuration

    4. Why this role exists  
Internet Gateways create no IAM role

    5. Why it can read this secret  
Internet Gateways never communicate with Secrets Manager

    6. Why it cannot read others
not applicable
```

```s
Route Table

    1. Why each rule exists  
Route Tables do not grant permissions to users or services, they control network routing

    2. What would break if removed  
subnets would lose their custom routes and fall back to the VPCs main route table if one exists, the EC2 instance could not reach the Internet, users could not reach the EC2 web server, software installation during application would fail

    3. Why broader access is forbidden  
Route Table does not grant permissions, it controls packet routing

    4. Why this role exists  
Route Tables create no IAM role, it provides a place to define network routes so AWS knows how traffic should leave the subnet

    5. Why it can read this secret  
Route Tables never interact with Secrets Manager

    6. Why it cannot read others
Networking resources do not access AWS Secrets

```

```s
Public Security Group

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```

```s
Private Security Group

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```

```s
RDS Database

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```

```s
Database Subnet Group

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```

```s
IAM

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```

```s
EC2

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```

```s
Internet Gateway

    1. Why each rule exists  

    2. What would break if removed  

    3. Why broader access is forbidden  

    4. Why this role exists  

    5. Why it can read this secret  
    
    6. Why it cannot read others
```
