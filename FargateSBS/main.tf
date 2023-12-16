provider "aws" {
  region = "ap-southeast-2"
}

module "s3" {
  source = "./modules/s3"
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
  cluster_name = "my-fargate-cluster"
}