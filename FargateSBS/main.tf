provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "SBS-tfstate-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "Dev"
  }
}

terraform {
  backend "s3" {
    bucket         = aws_s3_bucket.terraform_state_bucket.bucket
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

module "ecs" {
  source       = "./modules/ecs"
  cluster_name = "SBS-fargate-cluster"
}