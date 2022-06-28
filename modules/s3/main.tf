locals {
  name = "${var.env}.${var.application}.${var.acl}.${var.env_group}.walletconnect"
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = var.acl
}
