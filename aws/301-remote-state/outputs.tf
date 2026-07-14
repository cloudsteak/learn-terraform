output "bucket_name" {
  description = "Name of the workload S3 bucket."
  value       = aws_s3_bucket.workload.bucket
}

output "bucket_arn" {
  description = "ARN of the workload S3 bucket."
  value       = aws_s3_bucket.workload.arn
}
