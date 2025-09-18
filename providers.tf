terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ⚠️ CE/Anomaly Detection opera en us-east-1
provider "aws" {
  region = var.region_ce
}