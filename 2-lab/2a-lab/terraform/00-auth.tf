terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.61.0"
    }
      random = {
    source  = "hashicorp/random"
    version = "3.6.3"
  }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "cloudfront"
  region = "us-east-1"
}