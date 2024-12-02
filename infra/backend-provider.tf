terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
  }
  backend "s3" {
    bucket  = "iac-terraform-api2"
    key     = "ecs/api.tfstate"
    region  = "us-east-1"
    dynamodb_table = "terraform_locks_api"
    profile = "proot"
  }
}

provider "aws" {
  region = var.region
  profile = var.profile
}

module "s3_tf-state" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "iac-terraform-api2"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  count        = terraform.workspace == "default" ? 1 : 0
  name         = "terraform_locks_${var.project}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_ecr_repository" "api" {
  name = "api"
}