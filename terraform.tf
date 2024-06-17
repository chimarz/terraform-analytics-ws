terraform {
  required_version = "~> 1.3.6"

  required_providers {
    # AWS Provider configuration 
    aws = {
      version               = "4.45"
    }
  }
}

provider "aws" {
  region = var.target_region
}