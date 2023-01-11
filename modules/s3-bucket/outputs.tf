output "bucket_domain_name" {
  value       = join("", aws_s3_bucket.this.bucket_domain_name)
  description = "FQDN of bucket"
}

output "bucket_regional_domain_name" {
  value       = join("", aws_s3_bucket.this.bucket_regional_domain_name)
  description = "The bucket region-specific domain name"
}

output "bucket_id" {
  value       = join("", aws_s3_bucket.this.id)
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = join("", aws_s3_bucket.this.arn)
  description = "Bucket ARN"
}

output "bucket_region" {
  value       = join("", aws_s3_bucket.this.region)
  description = "Bucket region"
}

output "replication_role_arn" {
  value       = var.s3_replication_enabled ? join("", aws_iam_role.replication.*.arn) : "" # tflint-ignore: terraform_deprecated_index
  description = "The ARN of the replication IAM Role"
}
