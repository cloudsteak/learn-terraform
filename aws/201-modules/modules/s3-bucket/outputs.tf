output "name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}
