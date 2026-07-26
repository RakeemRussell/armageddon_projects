output "sns_db_error_tf_topic_arn" {
  description = "SNS Topic ARN for database incidents."
  value       = aws_sns_topic.sns_db_error_tf.arn
}

output "iam_role_auto_grader_arn" {
  description = "IAM role ARN to assume for temporary Lab 1b incident injection."
  value       = aws_iam_role.auto_grader.arn
}
