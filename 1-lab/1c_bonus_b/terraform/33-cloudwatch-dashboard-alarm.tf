### CLOUDWATCH DASHBOARD (Bonus-B)
resource "aws_cloudwatch_dashboard" "bonusb_dashboard" {
  dashboard_name = "chewbacca-bonusb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Request Count"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.alb_bonus_b.arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Target Response Time"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb_bonus_b.arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Target Health (Healthy vs Unhealthy)"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Average"
          period  = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.tg_bonus_b.arn_suffix, "LoadBalancer", aws_lb.alb_bonus_b.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.tg_bonus_b.arn_suffix, "LoadBalancer", aws_lb.alb_bonus_b.arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB 4xx / 5xx Errors"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.alb_bonus_b.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", aws_lb.alb_bonus_b.arn_suffix]
          ]
        }
      }
    ]
  })
}

### CLOUDWATCH ALARM: ALB 5xx SPIKE
# Wired to the existing SNS topic from Lab 1b (sns_db_error_tf), reusing the
# same incident-notification channel rather than creating a new one.
resource "aws_cloudwatch_metric_alarm" "alb_5xx_alarm" {
  alarm_name          = "chewbacca-alb-5xx-spike"
  alarm_description   = "Triggers when the Bonus-B ALB returns a spike of 5xx errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.alb_bonus_b.arn_suffix
  }

  alarm_actions = [aws_sns_topic.sns_db_error_tf.arn]
  ok_actions    = [aws_sns_topic.sns_db_error_tf.arn]

  tags = {
    Name = "chewbacca-alb-5xx-spike"
  }
}
