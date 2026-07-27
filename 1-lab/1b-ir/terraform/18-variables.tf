variable "email_alert" {
  description = "Email address to receive error notifications."
  type        = string
}

variable "iam_role_auto_grader_arn" {
  description = "IAM user or role ARN allowed to assume the temporary Lab 1b incident injector role."
  type        = string
}

variable "log_group_name" {
  type    = string
  default = "/aws/ec2/lab-rds-app"
}