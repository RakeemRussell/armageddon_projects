# AWS EC2-RDS Notes Application with Terraform

## Overview

This project demonstrates how to deploy a secure, three-tier AWS application using Terraform.

The application runs on an Amazon EC2 instance, securely stores its data in an Amazon RDS MySQL database, and retrieves database credentials dynamically from AWS Secrets Manager using an IAM Role attached to the EC2 instance.

The infrastructure follows AWS security best practices by isolating the database in a private subnet while exposing only the web application to the internet.

---

## Architecture

![Architecture Diagram](docs/diagrams/architecture-diagram.png)

---

## Features

* Infrastructure provisioned entirely with Terraform
* Custom VPC with public and private subnets
* EC2-hosted Flask application
* Amazon RDS MySQL database
* IAM Role and Instance Profile for secure AWS authentication
* AWS Secrets Manager integration
* Dynamic configuration using Terraform `templatefile()`
* Automatic application deployment using EC2 User Data
* Least-privilege security model
* Documented troubleshooting and engineering decisions

---

## Technologies Used

### Cloud

* AWS
* Amazon EC2
* Amazon RDS
* Amazon VPC
* Internet Gateway
* Route Tables
* Security Groups
* IAM
* IAM Instance Profiles
* AWS Secrets Manager

### Infrastructure as Code

* Terraform

### Operating System

* Amazon Linux

### Application

* Python
* Flask
* boto3
* PyMySQL
* systemd

---

## Application Endpoints

`Initialize the database`

```b
http://<EC2_PUBLIC_IP>/init
```

`Insert a note`

```b
http://<EC2_PUBLIC_IP>/add?note=first_note
```

`Display stored notes`

```b
http://<EC2_PUBLIC_IP>/list
```

---

## Repository Structure

![Architecture Diagram](screenshots/troubleshooting/sg18.png)

---

## Documentation

Additional project documentation can be found in the **docs** directory.

| Document                   | Description                                                              |
|----------------------------|--------------------------------------------------------------------------|
| `project-summary.md`       | Project objectives, AWS services used, workflow, and skills demonstrated |
| `architecture-overview.md` | Explanation of the AWS architecture and security model                  |
| `deployment-notes.md`      | Deployment steps, application endpoints, and cleanup instructions        |
| `troubleshooting-log.md`   | Issues encountered during development and their resolutions              |
| `lessons-learned.md`       | Engineering principles and key takeaways from the project                |
| `design-decisions.md`      | Reason behind architectural and implementation choices                   |

---

## Screenshots

### Terraform Deployment

`Terraform validate`  
![Architecture Diagram](screenshots/troubleshooting/sg19.png)

`Terraform plan`
![Architecture Diagram](screenshots/troubleshooting/sg20.png)
![Architecture Diagram](screenshots/troubleshooting/sg21.png)

`Terraform apply -auto-approve`
![Architecture Diagram](screenshots/troubleshooting/sg22.png)
![Architecture Diagram](screenshots/troubleshooting/sg23.png)

`Terraform destroy -auto-approve`  
![Architecture Diagram](screenshots/troubleshooting/sg24.png)
![Architecture Diagram](screenshots/troubleshooting/sg35.png)

### AWS Infrastructure

`VPC`  
![Architecture Diagram](screenshots/troubleshooting/sg25.png)

`SUBNETS`  
![Architecture Diagram](screenshots/troubleshooting/sg26.png)
`SECURITY GROUPS`  
![Architecture Diagram](screenshots/troubleshooting/sg27.png)
`EC2 INSTANCES`  
![Architecture Diagram](screenshots/troubleshooting/sg28.png)
`DATABASES`  
![Architecture Diagram](screenshots/troubleshooting/sg29.png)

`EC2 IAM ROLES`
![Architecture Diagram](screenshots/troubleshooting/sg30.png)

`EC2 IAM POLICIES`
![Architecture Diagram](screenshots/troubleshooting/sg31.png)

### Application End-Points

`Database initialization`  
![Architecture Diagram](screenshots/troubleshooting/sg32.png)

`Insert note`  
![Architecture Diagram](screenshots/troubleshooting/sg33.png)

`List notes`  
![Architecture Diagram](screenshots/troubleshooting/sg34.png)

---

## Skills Demonstrated

* Infrastructure as Code (Terraform)
* AWS Networking
* Identity and Access Management (IAM)
* Secrets Management
* Linux Administration
* Infrastructure Automation
* Secure Cloud Architecture
* Database Administration
* Python Web Application Deployment
* Cloud Troubleshooting
* Infrastructure Debugging

---
