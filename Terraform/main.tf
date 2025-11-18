terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
  bucket         = "abhishek-112233-bucket"
  key            = "eks/terraform.tfstate"   # path inside the bucket
  region         = "us-east-1"
  dynamodb_table = "terraform-lock-table"
  encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source = "hashicorp/tls"
    }

    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "local" {

}


