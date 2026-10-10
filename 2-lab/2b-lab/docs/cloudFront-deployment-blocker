# Lab 2a / 2b: CloudFront Deployment Blocker

## Summary

I could not deploy the CloudFront distribution for Lab 2a, so I could not run the CloudFront-dependent verification CLI checks (and the matching Lab 2b `curl` proofs). The cause is an **AWS account-level restriction**, not a Terraform or configuration error. AWS blocks new CloudFront distributions on accounts that are still new and have little usage and spend history. AWS Support reviewed my request, escalated it to the CloudFront service team, and denied it for now.

| | |
|---|---|
| **AWS Support case ID** | `178968094500258` |
| **Failing resource** | `aws_cloudfront_distribution.cf_distribution` |
| **API call** | `CloudFront: CreateDistributionWithTags` |
| **HTTP status** | `403 AccessDenied` |
| **Request ID** | `7234e2bb-b168-441b-8ef1-aa9702cef66b` |
| **Error message** | "Your account must be verified before you can add new CloudFront resources. To verify your account, please contact AWS Support." |
| **AWS Support decision (Sep 30, 2026)** | Denied for now: the account is relatively new and needs to build usage and spend history first |

## Exact error from `terraform apply`

Raw output as captured from the terminal:

```
Error: creating CloudFront Distribution: operation error CloudFront: CreateDistributionWithTags,
https response error StatusCode: 403, RequestID: 7234e2bb-b168-441b-8ef1-aa9702cef66b,
AccessDenied: Your account must be verified before you can add new CloudFront resources.
To verify your account, please contact AWS Support
(https://console.aws.amazon.com/support/home#/) and include this error message.

  with aws_cloudfront_distribution.cf_distribution,
  on 34-cloudfront.tf line 246, in resource "aws_cloudfront_distribution" "cf_distribution":
 246: resource "aws_cloudfront_distribution" "cf_distribution" {
```

## Timeline

| Date | Event |
|---|---|
| Before Sep 17 | Built the Lab 2a Terraform. An earlier full apply hung for 70+ minutes because both ACM certificates stayed `PENDING_VALIDATION`. Root cause: my domain `bonusb.online` was suspended by the registrar (Namecheap) pending contact-information verification. I verified my contact information and the suspension was lifted. **That was a separate, resolved issue.** |
| Sep 17, 2026 | Re-ran `terraform apply`. Both ACM certificates validated this time, and the apply proceeded up to the CloudFront distribution, where it failed with the 403 above. |
| Sep 17, 2026 | Opened AWS Support case `178968094500258` with the error message and Request ID. Support escalated it to the CloudFront service team. |
| Sep 30, 2026 | AWS Support relayed the service team's decision: denied for now, account too new. Recommended ramping up usage and re-requesting after the next billing cycle. |

## Why this is not a configuration problem

- `terraform validate` passes on the full configuration.
- `terraform plan` completed cleanly (93 resources to add, 0 to destroy; the one in-place change was a harmless metadata default on a Route 53 zone I had imported at the time and later removed from Terraform management).
- On the apply that reached the distribution, both ACM certificates (the CloudFront viewer cert in us-east-1 and the ALB origin cert) validated successfully through DNS before the failure.
- The error is returned by the CloudFront API itself, before any distribution configuration is evaluated. AWS Support confirmed the cause is the account's age and usage history, not my configuration.

## What is complete

**Lab 2a (Terraform written and validated):**
- CloudFront origin-facing managed prefix list lookup, plus an ALB security group rule restricting inbound 443 to it (layer 1 of origin cloaking)
- Secret origin header (`random_password`), plus two ALB listener rules: forward only when the header matches, otherwise a fixed 403 (layer 2)
- CLOUDFRONT-scope WAFv2 web ACL (Common + KnownBadInputs managed rule groups), created via a `us-east-1` provider alias
- Two DNS-validated ACM certificates (CloudFront viewer cert and ALB origin cert)
- CloudFront distribution with the ALB as an HTTPS-only origin, custom header, WAF attached, and aliases for the apex and `app` hostnames
- Route 53 alias records for the apex and `app` hostnames pointing at CloudFront

**Lab 2b (Terraform written and validated):**
- Static and API cache policies, static and API origin request policies, and a response headers policy for explicit `Cache-Control`
- Ordered cache behaviors for `/static/*` and `/api/*`, with the API-safe policies as the default behavior
- App changes so the lab's test paths exist: `/static/example.txt` and `/api/list`
- Deliverable B written explanation (cache key and origin forwarding) and Deliverable C haiku

## What cannot be completed until CloudFront is available

**Lab 2a verification (CLI):**
- `curl -I https://bonusb.online` and `curl -I https://app.bonusb.online` returning 200 via CloudFront
- `aws wafv2 get-web-acl --scope CLOUDFRONT ...` and `aws cloudfront get-distribution ... WebACLId` confirming the WAF is attached to the distribution
- `dig bonusb.online A +short` and `dig app.bonusb.online A +short` resolving to CloudFront

**Lab 2b verification (CLI):**
- Deliverable B: `curl -I` output for `/static/example.txt` and `/api/list`
- Deliverable D: static caching proof (`Cache-Control`, `Age` increasing), API not cached, query-string cache-key check, stale-read-after-write test

## Path to unblock

AWS Support's recommendation was to ramp up usage on the account, wait for the next billing cycle, and then raise a new request. Plan:

1. Keep using the account normally so it builds usage and spend history.
2. After the next billing cycle, reopen the support request (reference case `178968094500258` and the Request ID above).
3. Once approved, run `terraform apply` (the configuration is ready as written), then run the full verification command set for Lab 2a and Lab 2b and add the output to this repository.

## Appendix: AWS Support correspondence

```
admin (IAM)
Thu Sep 17 2026
17:35:47 GMT-0400 (Eastern Daylight Time)

Subject: CloudFront AccessDenied - Account verification required for new resources

Hello AWS Support Team,

I am attempting to create a new CloudFront distribution, but my deployment is failing with an
AccessDenied error indicating that my account must be verified.

Here are the specific details of the error:

* Error Message: AccessDenied: Your account must be verified before you can add new CloudFront resources
* Request ID: 7234e2bb-b168-441b-8ef1-aa9702cef66b

Could you please review my account and complete the necessary manual verification steps so I can
begin provisioning CloudFront resources? Please let me know if you need any additional information
or verification details from my end to expedite this process.

Thank you for your assistance.

---

admin (IAM)
Thu Sep 17 2026
17:35:53 GMT-0400 (Eastern Daylight Time)

03:17:21 AM Manpreet: Hello, my name is Manpreet and I am here to assist you today. While I review
your case details, would you mind sharing your preferred name?
03:17:47 AM Manpreet:
We understand that you're encountering an issue while trying to launch CloudFront on your account,
as it prompts you to verify your account. We apologize for any inconvenience this may have caused.
Rest assured, we'll assist you in resolving this issue.

To ensure a precise resolution, we've escalated the matter to our service team by creating an
internal ticket. They have the necessary tools to investigate the issue in more detail.

We kindly request your patience while we work with the service team to review this issue in detail
for you. Your understanding and co-operation in this matter is greatly appreciated.

---

admin (IAM)
Thu Sep 17 2026
23:51:57 GMT-0400 (Eastern Daylight Time)

Will I recive an update for this case via email or this chat?

---

Amazon Web Services
Wed Sep 30 2026
08:12:44 GMT-0400 (Eastern Daylight Time)

Dear Customer,

We really appreciate your patience while we were awaiting a response from our service team.

Firstly, we would like to express our gratitude for your time and your continued patience as we
diligently work on your request. Your understanding and cooperation are greatly appreciated.

We recently received an update from our service team taken care of reviewing your request. To
ensure complete transparency, We are copy pasting their response on the request raised. They have
updated " Account is relatively new and needs to build usage and spend history, before granting
such a request.

" We can't grant you access to Amazon CloudFront distributions at this time. We recommend that you
gradually ramp up usage on your account. When you have a broader period of usage on your account,
our service team will review additional access requests."

We're happy to share with you some recommendations in case you'd like to ask for it again. We hope
you find them helpful.

> Wait for the next billing cycle in order to process the limit and raise a limit increase request,
once you have some usage on the account.

We want you to know that we are just an intermediary here and these requests are not under our
control but for any concerns you may have, we will definitely try our best here by reaching out to
the service team again.

Please feel free to contact us if you any further clarification, and we'd be more than happy to
help you. You can reach out to us by opening chat for immediate and live support:

1. Please enable pop-ups from your browser settings to allow the chat window to open successfully.
2. Click "Reply" from this case.
3. Select "Chat" from the contact method options.
4. Click "Submit" and an available agent will assist you straight away.

We value and appreciate your engagement with us. Thank you so much for your kind understanding in
this matter.

Please stay safe and take care!

We value your feedback. Please share your experience by rating this and other correspondences in
the AWS Support Center. You can rate a correspondence by selecting the stars in the top right
corner of the correspondence.

Best regards,
Manpreet .
Amazon Web Services
```