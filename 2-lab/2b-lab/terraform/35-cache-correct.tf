##############################################
# Lab 2b - CloudFront cache correctness
# Overlay on top of Lab 2a's aws_cloudfront_distribution.cf_distribution
##############################################

### CACHE POLICY: STATIC (aggressive caching)
# Ignores query strings, headers, and cookies entirely so the cache key
# stays small and hit ratio stays high - a versioned query string like
# ?v=1 vs ?v=2 still maps to the same cached object by design.
resource "aws_cloudfront_cache_policy" "cache_static" {
  name        = "bonusb-cache-static01"
  comment     = "Aggressive caching for /static/* - ignores query strings, headers, cookies"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

### CACHE POLICY: API (caching disabled, safe default)
# min/default/max ttl of 0 means CloudFront always revalidates with the
# origin instead of serving a cached copy - the safe default for
# anything that could return per-user or just-written data.
resource "aws_cloudfront_cache_policy" "cache_api_disabled" {
  name        = "bonusb-cache-api-disabled01"
  comment     = "Caching disabled for /api/* and default behavior - safe default for dynamic responses"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

### ORIGIN REQUEST POLICY: STATIC (minimal forwarding)
# Static files don't need cookies, headers, or query strings forwarded
# to the origin at all - fewer variables forwarded means fewer ways to
# accidentally fragment or leak the cache.
resource "aws_cloudfront_origin_request_policy" "orp_static" {
  name    = "bonusb-orp-static01"
  comment = "Minimal forwarding for /static/*"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

### ORIGIN REQUEST POLICY: API (forward what origin needs)
# The API needs headers/cookies/query strings available to the origin
# to behave correctly (e.g. auth headers, pagination query params) -
# but this is a separate concern from the cache KEY, which the cache
# policy above controls. Forwarding something to origin doesn't mean
# it's used to decide what gets cached.
resource "aws_cloudfront_origin_request_policy" "orp_api" {
  name    = "bonusb-orp-api01"
  comment = "Forward headers/cookies/query strings needed by the API to the origin"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

### RESPONSE HEADERS POLICY: explicit Cache-Control for static responses
# CloudFront/AWS recommend Cache-Control max-age over the older Expires
# header - this makes the caching behavior visible and provable via
# curl -I, rather than relying only on the cache policy's internal TTL.
resource "aws_cloudfront_response_headers_policy" "static_cache_control" {
  name    = "bonusb-static-cache-control01"
  comment = "Explicit Cache-Control header for /static/* responses"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=86400"
      override = true
    }
  }
}

### PATCH THE DISTRIBUTION: default behavior + ordered /static/* behavior
# default_cache_behavior is redefined here (replacing Lab 2a's
# forwarded_values-based version) to use the API-safe cache policy by
# default - cache_policy_id/origin_request_policy_id cannot be combined
# with forwarded_values on the same behavior, so this fully replaces it.
# An ordered_cache_behavior is added for /static/* specifically, which
# CloudFront evaluates before falling through to the default.
