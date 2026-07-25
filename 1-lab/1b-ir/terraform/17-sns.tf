resource "aws_sns_topic" "sns_db_error_tf" {
  name = "sns_db_error_aws"

  tags = {
    Name        = "sns_db_error_tf"
    Environment = "lab_ir"
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.sns_db_error_tf.arn
  protocol  = "email"
  endpoint  = var.email_alert
}

variable "alert_email" {
  description = "receives error notifications."
  type        = string
}