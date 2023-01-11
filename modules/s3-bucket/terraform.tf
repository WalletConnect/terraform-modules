# Terraform Configuration
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
