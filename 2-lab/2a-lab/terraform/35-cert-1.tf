resource "aws_acm_certificate" "viewer_facing_cert" {
  provider                  = aws.cloudfront
  domain_name                = "bonusb.online"
  subject_alternative_names = ["app.bonusb.online"]
  validation_method          = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

