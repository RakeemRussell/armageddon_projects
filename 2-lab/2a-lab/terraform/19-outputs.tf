output "sns_db_error_tf_topic_arn" {
  description = "SNS Topic ARN for database incidents."
  value       = aws_sns_topic.sns_db_error_tf.arn
}

output "iam_role_auto_grader_arn" {
  description = "IAM role ARN to assume for temporary Lab 1b incident injection."
  value       = aws_iam_role.auto_grader.arn
}

output "gcp_region" {
  value = var.aws_region
}

output "gcp_secret_id" {
  value = aws_secretsmanager_secret.db_secret.name
}



output "db_instance_id" {
  value = aws_db_instance.mysql_rds_db.identifier
}

output "rds_security_group_id" {
  value = aws_security_group.sg_private_resource.id
}

output "ec2SecurityGroupId" {
  value = aws_security_group.sg_ec2_lab.id
}

output "ec2_public_ipv4" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.ec2_public.public_ip
}

output "ec2_private_instance_id" {
  value = aws_instance.ec2_private.id
}

output "vpc_id" {
  value = aws_vpc.vpc_resource.id
}