output "s3_bucket_name" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend_cdn.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}