##############################################
# Lab 2a - CloudFront Origin Cloaking
# Overlay on top of Lab 1c / Bonus-A / Bonus-B
##############################################

# NOTE: bonusb.online is looked up read-only via the existing
# data "aws_route53_zone" "bonusb_online" source (declared in
# 31-alb-listeners.tf). An earlier attempt at managing this zone as a
# real Terraform resource (aws_route53_zone.route_zone_1, imported via
# `terraform import`) was removed after `terraform destroy` tried to
# delete the real, live hosted zone - which would have broken the
# domain's nameserver delegation at Namecheap. A `data` source can
# never be destroyed, so this is the safer long-term approach.

### CLOUDFRONT ORIGIN-FACING PREFIX LIST
# AWS-managed, auto-updated list of IP ranges CloudFront uses to reach
# origins. Looked up here so the ingress rule below can reference its ID.
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

### ALB SG INGRESS: ONLY FROM CLOUDFRONT (Layer 1 of origin cloaking)
# Restricts the ALB's security group to only accept HTTPS traffic from
# IPs in the CloudFront origin-facing prefix list above. Not airtight on
# its own - anyone can point their own CloudFront distribution at this
# ALB's DNS name and still pass this check, since their IPs are in the
# same shared prefix list. Layer 2 (secret header, below) is what
# actually proves the request came through *our* distribution.
resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress_rule" {
  security_group_id = aws_security_group.sg_alb_bonus_b.id
  prefix_list_id     = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
  from_port          = 443
  ip_protocol        = "tcp"
  to_port            = 443
}

##############################################
# Secret origin header: second defense-in-depth layer
##############################################

### RANDOM SECRET VALUE
# CloudFront's origin config (built later) will inject this as a custom
# header on every request it sends to the ALB. The ALB only forwards
# requests carrying the matching value - this is what actually proves a
# request came through *our* distribution specifically, since the SG
# rule above can't distinguish our distribution from anyone else's.
resource "random_password" "secret_header_value" {
  length  = 32
  special = false
}

### LISTENER RULE: HEADER MATCH -> FORWARD (evaluated first, priority 10)
resource "aws_lb_listener_rule" "origin_header01_listener_rule" {
  listener_arn = aws_lb_listener.https_forward.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_bonus_b.arn
  }

  condition {
    http_header {
      http_header_name = "cloudfront-header-name"
      values           = [random_password.secret_header_value.result]
    }
  }
}

### LISTENER RULE: CATCH-ALL -> FIXED 403 (evaluated after, priority 90)
resource "aws_lb_listener_rule" "origin_header01_listener_rule_catch_all" {
  listener_arn = aws_lb_listener.https_forward.arn
  priority     = 90

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "nope, access forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

##############################################
# WAF moves to CloudFront (CLOUDFRONT scope)
##############################################

### CLOUDFRONT-SCOPE WEB ACL
# Net-new resource rather than converting waf_bonus_b in place, because
# WAFv2 `scope` is immutable (ForceNew) - Terraform would destroy and
# recreate either way. Carries both managed rule groups from the
# original bonusb-waf01 (Common + KnownBadInputs) so moving enforcement
# to the edge doesn't lose coverage. Uses the aws.cloudfront aliased
# provider since CLOUDFRONT-scope Web ACLs must be created via us-east-1.
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

  rule {
    name     = "waf_acl_known_bad_inputs_rule"
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
      metric_name                = "visibility_config_name_bad"
      sampled_requests_enabled   = true
    }
  }
}

# NOTE: once the CloudFront distribution (next step) references
# aws_wafv2_web_acl.waf_acl.arn via its web_acl_id argument, delete the
# old aws_wafv2_web_acl_association.waf_alb_association and
# aws_wafv2_web_acl.waf_bonus_b resources from 32-waf.tf - WAF no longer
# belongs on the ALB once CloudFront is the public ingress.

##############################################
# ACM certificates
##############################################

### CLOUDFRONT VIEWER CERT (us-east-1, apex + app subdomain)
resource "aws_acm_certificate" "viewer_facing_cert" {
  provider                  = aws.cloudfront
  domain_name                = "bonusb.online"
  subject_alternative_names = ["app.bonusb.online"]
  validation_method          = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.viewer_facing_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.bonusb_online.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.cloudfront
  certificate_arn         = aws_acm_certificate.viewer_facing_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record : record.fqdn]
}

### ALB ORIGIN CERT (default region, app subdomain only)
resource "aws_acm_certificate" "alb_origin_cert" {
  domain_name       = "app.bonusb.online"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_origin_record" {
  for_each = {
    for dvo in aws_acm_certificate.alb_origin_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.bonusb_online.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb_origin_cert_validated" {
  certificate_arn         = aws_acm_certificate.alb_origin_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_origin_record : record.fqdn]
}

##############################################
# CloudFront distribution: sole public ingress
##############################################

resource "aws_cloudfront_distribution" "cf_distribution" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "cf distribution resorce"

  origin {
    origin_id   = "origin_id"
    domain_name = aws_lb.alb_bonus_b.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "cloudfront-header-name"
      value = random_password.secret_header_value.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "origin_id"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  web_acl_id = aws_wafv2_web_acl.waf_acl.arn

  aliases = [
    "bonusb.online",
    "app.bonusb.online"
  ]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

##############################################
# Route53: apex record to CloudFront
##############################################
# app.bonusb.online is already handled by app_alias in 31-alb-listeners.tf
# (repointed at cf_distribution). This is the missing apex/root record -
# no bonusb.online record existed before this lab.
resource "aws_route53_record" "apex_record" {
  zone_id = data.aws_route53_zone.bonusb_online.zone_id
  name    = "bonusb.online"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cf_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
