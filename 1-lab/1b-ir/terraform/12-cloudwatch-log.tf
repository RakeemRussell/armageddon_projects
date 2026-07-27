resource "aws_cloudwatch_log_group" "cloudwatch_log" {
  name              = "var.log_group_name"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_metric_filter" "db_error_metric_tf" {

  name = "lab-db-connection-errors"

  log_group_name = aws_cloudwatch_log_group.cloudwatch_log.name

  pattern = "ERROR"

  metric_transformation {
    name      = "DBConnectionErrors"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_alarm_tf" {

  alarm_name = "lab-db-connection-failure"

  namespace = "Lab/RDSApp"

  metric_name = "DBConnectionErrors"

  statistic = "Sum"

  period = 300

  evaluation_periods = 1

  threshold = 2

  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.sns_db_error_tf.arn]

  alarm_description = "Alarm when database connection failures occur"
}
