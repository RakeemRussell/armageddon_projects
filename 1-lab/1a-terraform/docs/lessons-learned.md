# Lessons Learned

This project reinforced several important cloud engineering concepts.

## Infrastructure and Applications Must Work Together

Successful cloud deployments require both infrastructure and application configuration to remain in sync. Database names, endpoints, ports, and runtime configuration must match across all components.

---

## Secrets Should Never Be Hardcoded

AWS Secrets Manager allows sensitive credentials to remain outside of source code.

Applications should retrieve secrets dynamically using IAM Roles rather than embedding credentials inside scripts or Terraform configuration.

---

## IAM Roles Provide Secure Access

Using IAM Roles and Instance Profiles eliminates the need for long-lived AWS access keys on EC2 instances while following the principle of least privilege.

---

## Read Application Logs First

Application failures appear as generic HTTP 500 errors.

Using commands:

* systemctl
* journalctl

Helped identify errors before changing AWS infrastructure.

---

## Terraform Templates Simplify Dynamic Configuration

Using `templatefile()` allowed Terraform to inject runtime values such as RDS endpoint and Secrets Manager ARN directly into the EC2 User Data script.

---

## Troubleshoot One Layer at a Time

Breaking problems into layers simplified troubleshooting.

1. Infrastructure
2. Networking
3. IAM
4. Secrets Manager
5. Application
6. Database

Verifying each layer independently reduced unnecessary changes and made root causes easier to identify.
