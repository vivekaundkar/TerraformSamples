provider "aws" {
  region = "us-east-1"  # Specify your desired AWS region
}

terraform {
  backend "s3" {
    bucket         = "your-unique-s3-bucket-name"
    key            = "path/to/terraform.tfstate"
    region         = "us-east-1"  # Specify the same or a different AWS region
    encrypt        = true
    dynamodb_table = "terraform_locks"
  }
}

resource "aws_elastic_beanstalk_application" "sample_app" {
  name = "SampleApp"
}

resource "aws_elastic_beanstalk_environment" "sample_environment" {
  name                = "SampleEnvironment"
  application         = aws_elastic_beanstalk_application.sample_app.name
  solution_stack_name = "64bit Amazon Linux 2 v5.4.5 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"  # Specify your desired instance type
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"  # Specify your desired Node.js environment
  }
}
