##############################################
# Lab 2a - CloudFront Origin Cloaking
# Overlay on top of Lab 1c / Bonus-A / Bonus-B
##############################################

### PROVIDER ALIAS FOR US-EAST-1
# CloudFront viewer certificates must live in us-east-1 regardless of
# which region the rest of the stack (ALB, VPC, EC2, RDS) runs in.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

### IMPORT EXISTING ROUTE53 HOSTED ZONE
# This zone already exists in AWS (delegated from Namecheap). We are
# bringing it under Terraform management via `terraform import` rather
# than creating a new zone, because a new zone would get a different
# set of AWS nameservers and break the existing delegation.
#
#   terraform import aws_route53_zone.bonusb_online <ZONE_ID>
#
# After import, `terraform plan` should show no changes. If it shows
# a diff, adjust this block to match what's actually in AWS before
# applying - do not let Terraform "fix" a real, working zone.
resource "aws_route53_zone" "bonusb_online" {
  name = "bonusb.online"

  tags = {
    Name = "bonusb-online-zone"
  }
}

# NOTE: 31-alb-listeners.tf currently defines
#   data.aws_route53_zone.bonusb_online
# as a separate data source lookup for the same zone. Once the resource
# above is imported, you can either:
#   (a) leave the data source as-is (it still works fine for reads), or
#   (b) replace references to the data source with
#       aws_route53_zone.bonusb_online.zone_id
# Pick one and be consistent - don't mix both across files without a
# reason, to avoid confusion about which is the "real" source of truth.

### ACM CERTIFICATE FOR CLOUDFRONT (bonusb.online + app.bonusb.online)
# DNS-validated end-to-end in Terraform so `terraform apply` finishes
# clean with no manual console step.
resource "aws_acm_certificate" "cf_cert" {
  provider                  = aws.us_east_1
  domain_name                = "bonusb.online"
  subject_alternative_names = ["app.bonusb.online"]
  validation_method          = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bonusb-cf-cert01"
  }
}

### DNS VALIDATION RECORDS
# for_each over domain_validation_options handles both SANs (apex +
# app.) automatically - no need for separate blocks per domain.
resource "aws_route53_record" "cf_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf_cert.domain_validation_options : dvo.domain_name => {
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

### WAIT FOR VALIDATION TO COMPLETE
# Downstream resources (the CloudFront distribution) should reference
# aws_acm_certificate_validation.cf_cert_validated.certificate_arn,
# NOT aws_acm_certificate.cf_cert.arn directly - this forces Terraform
# to wait for ACM to actually issue the cert before CloudFront is built,
# avoiding a race where the distribution references an unissued cert.
resource "aws_acm_certificate_validation" "cf_cert_validated" {
  provider                = aws.us_east_1
  certificate_arn          = aws_acm_certificate.cf_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cf_cert_validation : record.fqdn]
}

##############################################
# ALB-region ACM certificate (replaces the deleted
# cert that data.aws_acm_certificate.app_cert in
# 31-alb-listeners.tf used to look up)
##############################################

### ACM CERTIFICATE FOR THE ALB (app.bonusb.online)
# Lives in whatever region the default provider points at (the ALB's
# region), separate from the us-east-1 CloudFront cert above. CloudFront
# terminates TLS at the edge with its own cert; the ALB terminates TLS
# again on the CloudFront -> ALB hop with this one. Two layers, two certs,
# on purpose - keeps them decoupled so removing CloudFront later doesn't
# require touching the ALB's cert, and vice versa.
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "app.bonusb.online"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bonusb-alb-cert01"
  }
}

### DNS VALIDATION RECORDS FOR THE ALB CERT
resource "aws_route53_record" "alb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options : dvo.domain_name => {
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

### WAIT FOR ALB CERT VALIDATION TO COMPLETE
resource "aws_acm_certificate_validation" "alb_cert_validated" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_cert_validation : record.fqdn]
}

##############################################
# Origin cloaking: lock ALB SG to CloudFront only
##############################################

### AWS-MANAGED PREFIX LIST FOR CLOUDFRONT ORIGIN-FACING IPs
# AWS maintains this list and updates it automatically as CloudFront's
# edge IP ranges change - referencing it by name means we never have to
# hardcode or manually update IP ranges ourselves.
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

### ALB SG INGRESS: ONLY FROM CLOUDFRONT
# Replaces alb_ingress_80 and alb_ingress_443 in 29-alb-sg.tf (both of
# which were 0.0.0.0/0 - delete those two resources from 29-alb-sg.tf).
# Port 80 is dropped entirely since CloudFront -> ALB is HTTPS-only per
# the lab; there's no reason for anything to reach the ALB on 80 anymore.
#
# Uses aws_vpc_security_group_ingress_rule to match the split-resource
# style already used in 29-alb-sg.tf, rather than the older
# aws_security_group_rule type.
#
# This is layer one of origin cloaking - by itself it's not airtight
# (anyone can stand up their own CloudFront distribution pointing at
# your ALB DNS name and would still pass this SG check), which is why
# the secret header check on the listener (next step) is required as
# the second, defense-in-depth layer.
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_cloudfront_only" {
  security_group_id = aws_security_group.sg_alb_bonus_b.id
  prefix_list_id     = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
  from_port          = 443
  ip_protocol        = "tcp"
  to_port            = 443
  description        = "HTTPS from CloudFront origin-facing prefix list only"
}

##############################################
# Secret origin header: second defense-in-depth layer
##############################################

### RANDOM SECRET VALUE
# Terraform-generated so it's never hand-typed or hardcoded. CloudFront's
# origin config (later file) injects this as a custom header on every
# request it sends to the ALB; the ALB only forwards requests carrying
# the matching value. The prefix-list SG rule alone isn't airtight since
# anyone can point their own CloudFront distribution at your ALB DNS name
# and still pass that check - this header is what actually proves the
# request came through *your* distribution specifically.
resource "random_password" "origin_header_value" {
  length  = 32
  special = false
}

### LISTENER RULE: HEADER MATCH -> FORWARD (evaluated first)
# Priority 10 so it's evaluated before the catch-all block rule below.
# Requests carrying the correct secret header get forwarded normally;
# everything else falls through to the default-block rule.
resource "aws_lb_listener_rule" "require_origin_header" {
  listener_arn = aws_lb_listener.https_forward.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_bonus_b.arn
  }

  condition {
    http_header {
      http_header_name = "X-Bonusb-Origin-Verify"
      values           = [random_password.origin_header_value.result]
    }
  }
}

### LISTENER RULE: CATCH-ALL -> FIXED 403 (evaluated last)
# Priority 99, matches any path. Anything that didn't match the header
# rule above (i.e. missing or wrong secret header - includes direct
# curl to the ALB DNS name) gets a 403 instead of falling through to the
# listener's normal default action. This leaves the listener's actual
# default_action untouched and uses rule priority instead, per the
# lab's reference pattern.
resource "aws_lb_listener_rule" "default_block" {
  listener_arn = aws_lb_listener.https_forward.arn
  priority     = 99

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
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
# recreate either way, so a clean net-new resource with its own name is
# the more honest representation of what's actually happening. Carries
# both managed rule groups from the original bonusb-waf01 (Common +
# KnownBadInputs) so moving enforcement to the edge doesn't lose
# coverage. Must be created via the us-east-1 provider even though
# CLOUDFRONT-scope Web ACLs are global - this is an AWS API requirement
# for the resource type, not a real regional restriction.
resource "aws_wafv2_web_acl" "waf_cf_bonusb01" {
  provider    = aws.us_east_1
  name        = "bonusb-cf-waf01"
  description = "CloudFront-edge managed protection for bonusb.online (replaces bonusb-waf01 on the ALB)"
  scope       = "CLOUDFRONT"

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
      metric_name                = "cfCommonRuleSet"
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
      metric_name                = "cfKnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "bonusbCfWaf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "bonusb-cf-waf01"
  }
}

# NOTE: once the CloudFront distribution (next step) references
# aws_wafv2_web_acl.waf_cf_bonusb01.arn via its web_acl_id argument,
# delete the old aws_wafv2_web_acl_association.waf_alb_association and
# aws_wafv2_web_acl.waf_bonus_b resources from 32-waf.tf - WAF no longer
# belongs on the ALB once CloudFront is the public ingress.

##############################################
# CloudFront distribution: sole public ingress
##############################################

### CLOUDFRONT DISTRIBUTION IN FRONT OF THE ALB
# Origin is the ALB's DNS name over HTTPS only. The custom header carries
# the same secret value the listener rules check for, so only requests
# that actually passed through this specific distribution get forwarded
# by the ALB. WAF is attached here (CLOUDFRONT scope), not on the ALB.
resource "aws_cloudfront_distribution" "bonusb_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "bonusb-cf01"

  origin {
    origin_id   = "bonusb-alb-origin01"
    domain_name = aws_lb.alb_bonus_b.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Bonusb-Origin-Verify"
      value = random_password.origin_header_value.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "bonusb-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # Using the legacy forwarded_values block to match the lab's base
    # template. This is deprecated in favor of cache_policy_id /
    # origin_request_policy_id but still functional - the honors
    # lab2b_cache_correctness.tf file appears to cover the modern
    # replacement, worth revisiting once we look at the honors files.
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  web_acl_id = aws_wafv2_web_acl.waf_cf_bonusb01.arn

  aliases = [
    "bonusb.online",
    "app.bonusb.online"
  ]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cf_cert_validated.certificate_arn
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
# Route53: point domain to CloudFront, not the ALB
##############################################

### APEX RECORD (bonusb.online -> CloudFront)
# No apex/root record existed before this lab - only app.bonusb.online
# was aliased (to the ALB). This is new.
resource "aws_route53_record" "apex_to_cf" {
  zone_id = data.aws_route53_zone.bonusb_online.zone_id
  name    = "bonusb.online"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.bonusb_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.bonusb_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# NOTE: the existing aws_route53_record.app_alias in 31-alb-listeners.tf
# currently points app.bonusb.online at the ALB. Don't add a third,
# competing record here - instead, edit that existing resource in place:
# change its `alias` block to reference
#   aws_cloudfront_distribution.bonusb_cf01.domain_name
#   aws_cloudfront_distribution.bonusb_cf01.hosted_zone_id
# instead of the ALB's dns_name / zone_id. Two aws_route53_record
# resources with the same name+type in the same zone will conflict in
# Terraform state, not just in AWS.
