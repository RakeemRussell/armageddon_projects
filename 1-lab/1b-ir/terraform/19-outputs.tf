output "sns_db_error_tf" {
  description = "SNS Topic ARN for database incidents."
  value       = aws_sns_topic.db_incidents.arn
}