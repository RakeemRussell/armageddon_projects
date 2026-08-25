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
