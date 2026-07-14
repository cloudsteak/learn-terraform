output "name" {
  description = "Name of the Cloud Storage bucket."
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "URL of the Cloud Storage bucket."
  value       = google_storage_bucket.this.url
}
