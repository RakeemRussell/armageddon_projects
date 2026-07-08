# Architecture Overview

![Architecture Diagram](./diagrams/architecture-diagram.png)

## Solution Architecture

The project deploys a three-tier application using AWS.

### Networking

A custom VPC contains:

* One Public Subnet
* One Private Subnet

The public subnet hosts the EC2 instance that serves the Flask web application.

The private subnet hosts the Amazon RDS MySQL database, preventing direct internet access.

An Internet Gateway allows inbound HTTP traffic to reach the EC2 instance.

---

## Compute Layer

An Amazon EC2 instance runs:

* Amazon Linux
* Python
* Flask
* boto3
* PyMySQL

The application is automatically installed and configured using an EC2 User Data script and runs as a systemd service.

---

## Identity and Security

The EC2 instance receives an IAM Instance Profile.

The attached IAM Role allows the application to retrieve only the required secret from AWS Secrets Manager.

No AWS access keys are stored on the EC2 instance.

---

## Database Layer

Amazon RDS MySQL stores all application data.

The database is deployed into a private subnet and is accessible only through the EC2 security group over TCP port 3306.

---

## Secrets Management

Database credentials are generated and managed by Amazon RDS using AWS Secrets Manager.

Rather than storing credentials inside Terraform or the application, the Flask application retrieves them dynamically using boto3.

Terraform injects the following runtime configuration into the application:

* Secret ARN
* RDS Endpoint
* Database Name
* Database Port

This separates authentication information from connection information while eliminating hardcoded credentials.
