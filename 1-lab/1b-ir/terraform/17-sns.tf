resource "aws_sns_topic" "sns_db_error_tf" {
  name = "sns-topic-name"

  tags = {
    Name        = "sns-topic-name-tag"
    Environment = "lab_ir"
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.sns_db_error_tf.arn
  protocol  = "email"
  endpoint  = var.email_alert
}
