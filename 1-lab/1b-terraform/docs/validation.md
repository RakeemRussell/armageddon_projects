# Validation Doc (documenting what and when resources work)

Terraform files 00-09 and user-data.sh works in 1b-terraform/terraform/

$ terraform validate  
Success! The configuration is valid.

$ terraform plan  
data.aws_iam_policy_document.ec2_assume_role: Reading...  
data.aws_iam_policy_document.ec2_assume_role: Read complete after 0s [id=2851119427]  
Plan: 22 to add, 0 to change, 0 to destroy.  

$ terraform apply -auto-approve  
data.aws_iam_policy_document.ec2_assume_role: Reading...  
data.aws_iam_policy_document.ec2_assume_role: Read complete after 0s [id=2851119427]  
Apply complete! Resources: 22 added, 0 changed, 0 destroyed.  

---

Application Endpoints, work:

```s
http://13.221.87.241/init

http://13.221.87.241/add?note=first_note

http://13.221.87.241/list
```

![Missing required provider](screenshots/sc_4.png)
![Missing required provider](screenshots/sc_5.png)
![Missing required provider](screenshots/sc_6.png)

---
$ terraform destroy -auto-approve  
Destroy complete! Resources: 22 destroyed.
