output "lab_db_incidents_topic_arn" {
  description = "SNS Topic ARN for database incidents."
  value       = aws_sns_topic.sns_db_error_tf.arn
}
