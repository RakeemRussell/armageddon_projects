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

  rule {
    name     = "waf_acl_rule"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "visibility_config_name"
      sampled_requests_enabled   = true
    }
  }
}