resource "aws_sns_topic" "sns_db_error_tf" {
  name = "lab-db-incidents"

  tags = {
    Name        = "lab-db-incidents"
    Environment = "lab_ir"
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.sns_db_error_tf.arn
  protocol  = "email"
  endpoint  = var.email_alert
}
