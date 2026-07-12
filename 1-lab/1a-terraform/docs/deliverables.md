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

Answer: Response
Why each rule exists
What would break if removed
Why broader access is forbidden
Why this role exists
Why it can read this secret
Why it cannot read others
