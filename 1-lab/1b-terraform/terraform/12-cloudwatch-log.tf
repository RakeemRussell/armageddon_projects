resource "aws_cloudwatch_log_group" "cloudwatch_log" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_metric_filter" "db_error_metric_tf" {

  name = "db_error_metric_aws"

  log_group_name = aws_cloudwatch_log_group.cloudwatch_log.name

  pattern = "ERROR"

  metric_transformation {
    name      = "db_error_connections"
    namespace = "rds/log"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_alarm_tf" {

  alarm_name = "db_alarm_aws"

  namespace = "rds/log"

  metric_name = "db_error_connections"

  statistic = "Sum"

  period = 60

  evaluation_periods = 1

  threshold = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_description = "Alarm when database connection failures occur"
}