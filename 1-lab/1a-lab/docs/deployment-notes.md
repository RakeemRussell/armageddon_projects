# Deployment Notes

## Prerequisites

* Terraform installed
* AWS CLI configured
* AWS account with appropriate permissions

---

## Deployment Steps

Initialize Terraform.

```bash
terraform init
```

Validate the configuration.

```bash
terraform validate
```

Generate the execution plan.

```bash
terraform plan
```

Deploy the infrastructure.

```bash
terraform apply -auto-approve
```

Terraform builds:

* VPC
* Public and Private Subnets
* Internet Gateway
* Route Tables
* Security Groups
* IAM Role
* IAM Instance Profile
* Amazon RDS
* Amazon EC2

The EC2 User Data script runs automatically:

* Installs Python
* Installs Flask
* Installs boto3
* Installs PyMySQL
* Creates the application
* Configures a systemd service
* Starts the web application

---

## Application Endpoints

Initialize the database.

```bash
http://<EC2_PUBLIC_IP>/init
```

Insert a note.

```bash
http://<EC2_PUBLIC_IP>/add?note=first_note
```

Retrieve all notes.

```bash
http://<EC2_PUBLIC_IP>/list
```

---

## Cleanup

Destroy all infrastructure.

```bash
terraform destroy -auto-approve
```
