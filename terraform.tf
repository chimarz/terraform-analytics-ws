terraform {
  required_version = "~> 1.6.0"

  required_providers {
    # AWS Provider configuration 
    aws = {
      version = "5.48"
    }
  }
}

provider "aws" {
  region = var.target_region
}