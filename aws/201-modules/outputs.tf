output "bucket_name" {
  description = "Name of the created S3 bucket."
  value       = module.s3_bucket.name
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket."
  value       = module.s3_bucket.arn
}
