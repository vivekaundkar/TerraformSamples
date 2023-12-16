provider "aws" {
  region = "ap-southeast-2"  # Update with your preferred region
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
