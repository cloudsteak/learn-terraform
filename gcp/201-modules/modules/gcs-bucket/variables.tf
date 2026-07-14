variable "location" {
  type        = string
  description = "GCP location for the bucket."
}

variable "name_suffix" {
  type        = string
  description = "Suffix for the bucket name (prefixed with the GCP project ID)."
}
