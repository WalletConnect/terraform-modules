variable "bucket_name" {
  type        = string
  default     = null
  description = "Bucket name. If provided, the bucket will be created with this name instead of generating the name from the context"
}

variable "acl" {
  type        = string
  default     = "private"
  description = <<-EOT
    The [canned ACL](https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl) to apply.
    `private` is recommended to avoid exposing sensitive information.
    Conflicts with `grants`.
    EOT
}

variable "grants" {
  type = list(object({
    id          = string
    type        = string
    permissions = list(string)
    uri         = string
  }))
  default = []

  description = <<-EOT
    A list of policy grants for the bucket, taking a list of permissions.
    Conflicts with `acl`. Set `acl` to `null` to use this.
    EOT
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    When `true`, permits a non-empty S3 bucket to be deleted by first deleting all objects in the bucket.
    THESE OBJECTS ARE NOT RECOVERABLE even if they were versioned and stored in Glacier.
    EOT
}

variable "versioning" {
  description = "Set to `true` to enable [versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html). Versioning is a means of keeping multiple variants of an object in the same bucket."
  type        = bool
  default     = false
}

variable "logging" {
  type = object({
    bucket_name = string
    prefix      = string
  })
  default     = null
  description = "Bucket access logging configuration."
}

variable "block_public_acls" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the [blocking of new public access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html) lists on the bucket."
}

variable "block_public_policy" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the [blocking of new public policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html) on the bucket."
}

variable "ignore_public_acls" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the [ignoring of public access lists](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html) on the bucket."
}

variable "restrict_public_buckets" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the [restricting of making the bucket public](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)."
}

variable "object_lock_configuration" {
  type = object({
    mode  = string # Valid values are GOVERNANCE and COMPLIANCE.
    days  = number
    years = number
  })
  default     = null
  description = <<-EOT
      A configuration for S3 object locking.
      With S3 Object Lock, you can store objects using a `write once, read many` (WORM) model. Object Lock can help prevent objects from being deleted or overwritten for a fixed amount of time or indefinitely.
      Valid values for `mode` are `GOVERNANCE` and `COMPLIANCE`.
    EOT
}

variable "transfer_acceleration_enabled" {
  type        = bool
  default     = false
  description = "Set this to true to enable S3 Transfer Acceleration for the bucket."
}

variable "s3_replication_enabled" {
  type        = bool
  default     = false
  description = "Set this to true and specify `s3_replication_rules` to enable replication. `versioning_enabled` must also be `true`."
}

variable "s3_replica_bucket_arn" {
  type        = string
  default     = ""
  description = <<-EOT
    A single S3 bucket ARN to use for all replication rules.
    Note: The destination bucket can be specified in the replication rule itself
    (which allows for multiple destinations), in which case it will take precedence over this variable.
    EOT
}

variable "s3_replication_rules" {
  type        = list(any)
  default     = null
  description = <<-EOT
    Specifies the replication rules for S3 bucket replication if enabled. You must also set s3_replication_enabled to true.
    ```
    type = list(object({
      id          = string
      priority    = number
      prefix      = string
      status      = string
      delete_marker_replication_status = string
      # destination_bucket is specified here rather than inside the destination object
      # to make it easier to work with the Terraform type system and create a list of consistent type.
      destination_bucket = string # destination bucket ARN, overrides s3_replica_bucket_arn

      destination = object({
        storage_class              = string
        replica_kms_key_id         = string
        access_control_translation = object({
          owner = string
        })
        account_id                 = string
        metrics                    = object({
          status = string
        })
      })
      source_selection_criteria = object({
        sse_kms_encrypted_objects = object({
          enabled = bool
        })
      })
      # filter.prefix overrides top level prefix
      filter = object({
        prefix = string
        tags = map(string)
      })
    }))
    ```
  EOT
}

variable "s3_replication_source_roles" {
  type        = list(string)
  default     = []
  description = "Cross-account IAM Role ARNs that will be allowed to perform S3 replication to this bucket (for replication within the same AWS account, it's not necessary to adjust the bucket policy)."
}

variable "bucket_key_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
  Set this to true to use Amazon S3 Bucket Keys for SSE-KMS, which reduce the cost of AWS KMS requests.
  For more information, see: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
  EOT
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
  validation {
    condition     = var.sse_algorithm == "AES256" || var.sse_algorithm == "aws:kms"
    error_message = "the SSE algorithm must be 'AES256' or 'aws:kms'."
  }
}

variable "kms_master_key_arn" {
  type        = string
  default     = null
  description = <<-EOT
      The AWS KMS master key ARN used for the `SSE-KMS` encryption.
      This can only be used when you set the value of `sse_algorithm` as `aws:kms`.
      The default aws/s3 AWS KMS master key is used if this element is absent while the `sse_algorithm` is `aws:kms`.
    EOT
}

variable "s3_object_ownership" {
  type        = string
  default     = "ObjectWriter"
  description = "Specifies the S3 [object ownership](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html) control. Valid values are `ObjectWriter`, `BucketOwnerPreferred`, and 'BucketOwnerEnforced'."
}

variable "source_policy_documents" {
  type        = list(string)
  default     = []
  description = <<-EOT
    List of IAM policy documents that are merged together into the exported document.
    Statements defined in source_policy_documents or source_json must have unique SIDs.
    Statement having SIDs that match policy SIDs generated by this module will override them.
    EOT
}
