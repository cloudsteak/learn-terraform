data "google_client_config" "current" {}

resource "google_storage_bucket" "main" {
  name     = "${data.google_client_config.current.project}-${var.bucket_name_suffix}"
  location = var.location
}
