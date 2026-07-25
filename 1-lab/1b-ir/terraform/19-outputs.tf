output "sns_db_error_tf" {
  description = "SNS Topic ARN for database incidents."
  value       = aws_sns_topic.sns_db_error_tf.arn
}