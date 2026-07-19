resource "aws_cloudwatch_log_group" "cloudwatch_log" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 1
}