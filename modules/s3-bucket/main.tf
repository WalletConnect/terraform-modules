locals {
  partition = join("", data.aws_partition.current.*.partition) # tflint-ignore: terraform_deprecated_index

  bucket_name = var.bucket_name != null && var.bucket_name != "" ? var.bucket_name : module.this.id
  bucket_arn  = "arn:${local.partition}:s3:::${join("", aws_s3_bucket.this.id)}"

  object_lock_enabled         = var.object_lock_configuration != null
  public_access_block_enabled = var.block_public_acls || var.block_public_policy || var.ignore_public_acls || var.restrict_public_buckets

  acl_grants = var.grants == null ? [] : flatten(
    [
      for g in var.grants : [
        for p in g.permissions : {
          id         = g.id
          type       = g.type
          permission = p
          uri        = g.uri
        }
      ]
  ])
}

data "aws_partition" "current" {}
data "aws_canonical_user_id" "default" {}

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "this" {
  bucket              = local.bucket_name
  force_destroy       = var.force_destroy
  object_lock_enabled = local.object_lock_enabled

  tags = var.tags
}

resource "aws_s3_bucket_accelerate_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  status = var.transfer_acceleration_enabled ? "Enabled" : "Suspended"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Disabled" #tfsec:ignore:aws-s3-enable-versioning
  }
}

resource "aws_s3_bucket_logging" "this" {
  count  = var.logging != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging["bucket_name"]
  target_prefix = var.logging["prefix"]
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id

  # Conflicts with access_control_policy so this is enabled if no grants
  acl = try(length(local.acl_grants), 0) == 0 ? var.acl : null

  dynamic "access_control_policy" {
    for_each = try(length(local.acl_grants), 0) == 0 || try(length(var.acl), 0) > 0 ? [] : [1]

    content {
      dynamic "grant" {
        for_each = local.acl_grants

        content {
          grantee {
            id   = grant.value.id
            type = grant.value.type
            uri  = grant.value.uri
          }
          permission = grant.value.permission
        }
      }

      owner {
        id = join("", data.aws_canonical_user_id.default.*.id) # tflint-ignore: terraform_deprecated_index
      }
    }
  }

}

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.s3_replication_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  role   = aws_iam_role.replication[0].arn

  dynamic "rule" {
    for_each = var.s3_replication_rules == null ? [] : var.s3_replication_rules

    content {
      id       = rule.value.id
      priority = try(rule.value.priority, 0)

      # `prefix` at this level is a V1 feature, replaced in V2 with the filter block.
      # `prefix` conflicts with `filter`, and for multiple destinations, a filter block
      # is required even if it empty, so we always implement `prefix` as a filter.
      # OBSOLETE: prefix   = try(rule.value.prefix, null)
      status = try(rule.value.status, null)

      # This is only relevant when "filter" is used
      delete_marker_replication {
        status = try(rule.value.delete_marker_replication_status, "Disabled")
      }

      destination {
        # Prefer newer system of specifying bucket in rule, but maintain backward compatibility with
        # s3_replica_bucket_arn to specify single destination for all rules
        bucket        = try(length(rule.value.destination_bucket), 0) > 0 ? rule.value.destination_bucket : var.s3_replica_bucket_arn
        storage_class = try(rule.value.destination.storage_class, "STANDARD")

        dynamic "encryption_configuration" {
          for_each = try(rule.value.destination.replica_kms_key_id, null) != null ? [1] : []

          content {
            replica_kms_key_id = try(rule.value.destination.replica_kms_key_id, null)
          }
        }

        account = try(rule.value.destination.account_id, null)

        # https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-walkthrough-5.html
        dynamic "metrics" {
          for_each = try(rule.value.destination.metrics.status, "") == "Enabled" ? [1] : []

          content {
            status = "Enabled"
            event_threshold {
              # Minutes can only have 15 as a valid value.
              minutes = 15
            }
          }
        }

        # This block is required when replication metrics are enabled.
        dynamic "replication_time" {
          for_each = try(rule.value.destination.metrics.status, "") == "Enabled" ? [1] : []

          content {
            status = "Enabled"
            time {
              # Minutes can only have 15 as a valid value.
              minutes = 15
            }
          }
        }

        dynamic "access_control_translation" {
          for_each = try(rule.value.destination.access_control_translation.owner, null) == null ? [] : [rule.value.destination.access_control_translation.owner]

          content {
            owner = access_control_translation.value
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = try(rule.value.source_selection_criteria.sse_kms_encrypted_objects.enabled, null) == null ? [] : [rule.value.source_selection_criteria.sse_kms_encrypted_objects.enabled]

        content {
          sse_kms_encrypted_objects {
            status = source_selection_criteria.value
          }
        }
      }

      # Replication to multiple destination buckets requires that priority is specified in the rules object.
      # If the corresponding rule requires no filter, an empty configuration block filter {} must be specified.
      # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
      dynamic "filter" {
        for_each = try(rule.value.filter, null) == null ? [{ prefix = null, tags = {} }] : [rule.value.filter]

        content {
          prefix = try(filter.value.prefix, try(rule.value.prefix, null))
          dynamic "tag" {
            for_each = try(filter.value.tags, {})

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }
    }
  }

  depends_on = [
    # versioning must be set before replication
    aws_s3_bucket_versioning.this
  ]
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count  = var.object_lock_configuration ? 1 : 0
  bucket = aws_s3_bucket.this.id

  object_lock_enabled = "Enabled"

  rule {
    default_retention {
      mode  = var.object_lock_configuration.mode
      days  = var.object_lock_configuration.days
      years = var.object_lock_configuration.years
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = local.public_access_block_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = var.bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_master_key_arn
    }
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  dynamic "statement" {
    for_each = length(var.s3_replication_source_roles) > 0 ? [1] : []

    content {
      sid = "CrossAccountReplicationObjects"
      actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionTagging",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ]
      resources = ["${local.bucket_arn}/*"]
      principals {
        type        = "AWS"
        identifiers = var.s3_replication_source_roles
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_replication_source_roles) > 0 ? [1] : []

    content {
      sid       = "CrossAccountReplicationBucket"
      actions   = ["s3:List*", "s3:GetBucketVersioning", "s3:PutBucketVersioning"]
      resources = [local.bucket_arn]
      principals {
        type        = "AWS"
        identifiers = var.s3_replication_source_roles
      }
    }
  }
}

data "aws_iam_policy_document" "aggregated_policy" {
  source_policy_documents   = data.aws_iam_policy_document.bucket_policy.*.json # tflint-ignore: terraform_deprecated_index
  override_policy_documents = var.source_policy_documents
}

resource "aws_s3_bucket_policy" "this" {
  count      = length(var.s3_replication_source_roles) > 0 || length(var.source_policy_documents) > 0 ? 1 : 0
  bucket     = aws_s3_bucket.this.id
  policy     = join("", data.aws_iam_policy_document.aggregated_policy.*.json) # tflint-ignore: terraform_deprecated_index
  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.s3_object_ownership
  }
  depends_on = [time_sleep.wait_for_aws_s3_bucket_settings]
}

# Workaround S3 eventual consistency for settings objects
resource "time_sleep" "wait_for_aws_s3_bucket_settings" {
  depends_on       = [aws_s3_bucket_public_access_block.this, aws_s3_bucket_policy.this]
  create_duration  = "30s"
  destroy_duration = "30s"
}
