### LOOK UP THE ALREADY-ISSUED ACM CERTIFICATE
# Requested and validated manually in the console for app.bonusb.online.
# Referenced here via data source rather than re-created as a resource,
# so Terraform doesn't try to request a duplicate certificate.


### HTTP LISTENER (port 80) - redirects everything to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.alb_bonus_b.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

### HTTPS LISTENER (port 443) - terminates TLS, forwards to target group
resource "aws_lb_listener" "https_forward" {
  load_balancer_arn = aws_lb.alb_bonus_b.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.alb_cert_validated.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_bonus_b.arn
  }
}

### DNS: point app.bonusb.online at CloudFront (not the ALB)
# Lab 2a: the ALB is no longer public ingress - CloudFront is. This
# record now aliases to the distribution instead of the ALB directly.
resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.bonusb_online.zone_id
  name    = "app.bonusb.online"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.bonusb_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.bonusb_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "bonusb_online" {
  name = "bonusb.online"
}
