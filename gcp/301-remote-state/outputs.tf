output "bucket_name" {
  description = "Name of the workload Cloud Storage bucket."
  value       = google_storage_bucket.workload.name
}

output "bucket_url" {
  description = "URL of the workload Cloud Storage bucket."
  value       = google_storage_bucket.workload.url
}
