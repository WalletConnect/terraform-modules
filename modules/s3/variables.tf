variable "env_group" {
  description = "AWS Environment Group(this is the account name on aws)"
}

variable "application" {
  description = "Application tag - A tag that uniquely identifies and application."
  type        = string
}

variable "env" {
  description = "Environment tag - Allowed values are dev, qc, stable, rc"
  type        = string
}

variable "tags" {
  type = map(string)
}

variable "acl" {
  default = "private"
}

variable "versioning" {
  default = false
}
