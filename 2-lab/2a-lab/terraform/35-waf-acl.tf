resource "aws_wafv2_web_acl" "waf_acl" {
  provider    = aws.cloudfront
  name        = "waf_acl_name"
  description = "waf_acl_description"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "visibility_metric_name"
    sampled_requests_enabled   = true
  }
}