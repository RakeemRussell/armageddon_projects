##############################################
# Lab 2a - CloudFront Origin Cloaking
# Overlay on top of Lab 1c / Bonus-A / Bonus-B
##############################################

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
# same shared prefix list. Layer 2 (secret header, next step) is what
# actually proves the request came through *our* distribution.
resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress_rule" {
  security_group_id = aws_security_group.sg_alb_bonus_b.id
  prefix_list_id     = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
  from_port          = 443
  ip_protocol        = "tcp"
  to_port            = 443
}

resource "aws_lb_listener_rule" "origin_header01_listener_rule" {
  listener_arn = aws_lb_listener.http_redirect.arn
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