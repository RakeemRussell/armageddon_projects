### WAF WEB ACL (Bonus-B)
resource "aws_wafv2_web_acl" "waf_bonus_b" {
  name        = "bonusb-waf01"
  description = "Baseline managed protection for the Bonus-B public ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
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
      metric_name                = "commonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "knownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "bonusbWaf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "bonusb-waf01"
  }
}

### ASSOCIATE THE WEB ACL WITH THE ALB
resource "aws_wafv2_web_acl_association" "waf_alb_association" {
  resource_arn = aws_lb.alb_bonus_b.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_bonus_b.arn
}
