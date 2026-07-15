output "bucket_name" {
  value = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "bucket_tags" {
  description = "Tags applied to the bucket, including provider default_tags"
  value       = aws_s3_bucket.main.tags
}
