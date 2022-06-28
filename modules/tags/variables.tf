variable "application" {
  description = "Application tag - A tag that uniquely identifies and application."
  type        = string
}

variable "env" {
  description = "Environment tag - Allowed values are dev, qc, stable, rc"
  type        = string
  default     = "dev"
}

variable "env_group" {
  description = "AWS Environment Group(this is the account name on aws)"
  default     = "walletconnect"
}

variable "additional_tags" {
  description = "Map of optional tags to consolidate with the required tags."
  type        = map(string)
  default     = {}
}
