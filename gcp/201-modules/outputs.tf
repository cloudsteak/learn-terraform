output "bucket_name" {
  description = "Name of the created Cloud Storage bucket."
  value       = module.gcs_bucket.name
}

output "bucket_url" {
  description = "URL of the created Cloud Storage bucket."
  value       = module.gcs_bucket.url
}
