resource "aws_cloudwatch_log_group" "cloudwatch_log" {
  name              = var.log_group_name
  retention_in_days = 1
}
#DB_AUTH_FAILURE
resource "aws_cloudwatch_log_metric_filter" "db_auth_failure" {

  name = "lab-db-authentication-errors"

  log_group_name = aws_cloudwatch_log_group.cloudwatch_log.name


  pattern = "DB_AUTH_FAILURE"


  metric_transformation {

    name = "DBAuthenticationFailures"

    namespace = "Lab/RDSApp"

    value = "1"

  }

}
#DB_CONNECTION_FAILURE
resource "aws_cloudwatch_log_metric_filter" "db_connection_failure" {


  name = "lab-db-connection-errors"


  log_group_name = aws_cloudwatch_log_group.cloudwatch_log.name


  pattern = "DB_CONNECTION_FAILURE"



  metric_transformation {

    name = "DBConnectionFailures"

    namespace = "Lab/RDSApp"

    value = "1"

  }

}
#DB_TIMEOUT_FAILURE
resource "aws_cloudwatch_log_metric_filter" "db_timeout_failure" {


  name = "lab-db-timeout-errors"


  log_group_name = aws_cloudwatch_log_group.cloudwatch_log.name


  pattern = "DB_TIMEOUT_FAILURE"



  metric_transformation {

    name = "DBTimeoutFailures"

    namespace = "Lab/RDSApp"

    value = "1"

  }

}
#Authentication Alarm
resource "aws_cloudwatch_metric_alarm" "db_auth_alarm" {


  alarm_name = "lab-db-auth-failure"


  namespace = "Lab/RDSApp"


  metric_name = "DBAuthenticationFailures"


  statistic = "Sum"


  period = 300


  evaluation_periods = 1


  threshold = 1


  comparison_operator = "GreaterThanOrEqualToThreshold"


  treat_missing_data = "notBreaching"


  alarm_actions = [
    aws_sns_topic.sns_db_error_tf.arn
  ]


  alarm_description = "Database authentication failures detected"

}
#Network Alarm
resource "aws_cloudwatch_metric_alarm" "db_connection_alarm" {


  alarm_name = "lab-db-network-failure"


  namespace = "Lab/RDSApp"


  metric_name = "DBConnectionFailures"


  statistic = "Sum"


  period = 300


  evaluation_periods = 1


  threshold = 1


  comparison_operator = "GreaterThanOrEqualToThreshold"



  treat_missing_data = "notBreaching"



  alarm_actions = [
    aws_sns_topic.sns_db_error_tf.arn
  ]


  alarm_description = "Database network connectivity failures detected"

}
#Timeout Alarm
resource "aws_cloudwatch_metric_alarm" "db_timeout_alarm" {


  alarm_name = "lab-db-timeout-failure"


  namespace = "Lab/RDSApp"


  metric_name = "DBTimeoutFailures"


  statistic = "Sum"


  period = 300


  evaluation_periods = 1


  threshold = 1


  comparison_operator = "GreaterThanOrEqualToThreshold"



  treat_missing_data = "notBreaching"



  alarm_actions = [
    aws_sns_topic.sns_db_error_tf.arn
  ]


  alarm_description = "Database timeout failures detected"

}