locals {
  tags = {
    Name             = var.application
    Application      = var.application
    EnvironmentGroup = var.env_group
    Env              = var.env
    ProvisionedBy    = "Terraform"
  }
}

output "tags" {
  description = "Combined map of required and optional tags."
  value       = merge(local.tags, var.additional_tags)
}
