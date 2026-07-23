# Project Summary

## Overview

This project demonstrates how to deploy a secure web application on AWS using Terraform. The application runs on an Amazon EC2 instance, stores its data in an Amazon RDS MySQL database, and securely retrieves database credentials from AWS Secrets Manager using an IAM Role attached to the EC2 instance.

The infrastructure follows AWS security best practices by placing the database in a private subnet while exposing only the web application to the internet.

---

## Objectives

* Provision AWS infrastructure using Terraform.
* Deploy a Flask application automatically with EC2 User Data.
* Store the application database in Amazon RDS.
* Protect database credentials using AWS Secrets Manager.
* Grant secure access through IAM Roles instead of access keys.
* Demonstrate infrastructure automation, security, and troubleshooting skills.

---

## AWS Services Used

* Amazon VPC
* Public and Private Subnets
* Internet Gateway
* Route Tables
* Security Groups
* Amazon EC2
* Amazon RDS (MySQL)
* AWS Secrets Manager
* IAM Roles
* IAM Instance Profiles
* Terraform

---

## Application Workflow

1. A user accesses the EC2 public IP from a web browser.
2. The Flask application receives the request.
3. The application assumes its IAM Role.
4. The application retrieves database credentials from AWS Secrets Manager.
5. Terraform provides the RDS endpoint and database name through the EC2 user-data template.
6. The application connects securely to the private RDS database.
7. Notes are created and retrieved from the database.

---

## Skills Demonstrated

* Infrastructure as Code (Terraform)
* AWS Networking
* IAM and Least Privilege Access
* Secrets Management
* Linux Administration
* Python Flask Deployment
* MySQL Administration
* Cloud Troubleshooting
* Infrastructure Debugging
