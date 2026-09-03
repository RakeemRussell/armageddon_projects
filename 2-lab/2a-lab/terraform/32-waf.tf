# WAF for the ALB was removed here in Lab 2a. Protection now lives at
# the CloudFront edge instead: see aws_wafv2_web_acl.waf_cf_bonusb01
# in 34-cloudfront.tf (CLOUDFRONT scope, both managed rule groups
# carried over from this file's old bonusb-waf01 for parity).
#
# Original REGIONAL WAF (aws_wafv2_web_acl.waf_bonus_b) and its
# association to the ALB (aws_wafv2_web_acl_association.waf_alb_association)
# were deleted - WAF no longer belongs on the ALB once CloudFront is the
# sole public ingress.
