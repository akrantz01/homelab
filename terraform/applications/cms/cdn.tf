locals {
  default_origin = module.bucket.domain_name
}

data "aws_cloudfront_cache_policy" "default" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "default" {
  name = "Managed-CORS-and-SecurityHeadersPolicy"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  comment = "CDN for cms.krantz.dev assets"

  http_version    = "http2and3"
  is_ipv6_enabled = true

  origin {
    origin_id   = local.default_origin
    domain_name = module.bucket.domain_name
  }

  default_cache_behavior {
    target_origin_id = local.default_origin

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.default.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.default.id

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
