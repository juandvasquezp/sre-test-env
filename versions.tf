terraform {
  required_version = "~> 1.16.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3.2"
    }
  }
}
