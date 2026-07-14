data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.name_suffix}"
}
