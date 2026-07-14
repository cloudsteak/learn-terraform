data "google_client_config" "current" {}

resource "google_storage_bucket" "this" {
  name     = "${data.google_client_config.current.project}-${var.name_suffix}"
  location = var.location
}
