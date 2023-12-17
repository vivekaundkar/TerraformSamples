provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "sbs-tfstate-bucket"
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
    bucket         = "sbs-tfstate-bucket"
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

resource "aws_ecs_cluster" "fargate_cluster" {
  name = var.cluster_name
}

# ECR Repository
data "aws_ecr_repository" "nginx_repo" {
  name = "vivekrepo"
}

# IAM Role for ECS Fargate Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach IAM Policy to ECS Fargate Execution Role
resource "aws_iam_policy_attachment" "ecs_execution_role_attachment" {
  name       = "ecs_execution_role_attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_execution_role.name]
}


# ECS Fargate Task Definition
resource "aws_ecs_task_definition" "nginx_task_definition" {
  family                   = "SBSFargateTaskDef"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu          = "512"
  memory       = "1024"

  execution_role_arn = "arn:aws:iam::239338699850:role/ecsTaskExecutionRole"
  task_role_arn = "arn:aws:iam::239338699850:role/ECSTaskServiceRole"

  runtime_platform {
    #Valid Values: WINDOWS_SERVER_2019_FULL | WINDOWS_SERVER_2019_CORE | WINDOWS_SERVER_2016_FULL | WINDOWS_SERVER_2004_CORE | WINDOWS_SERVER_2022_CORE | WINDOWS_SERVER_2022_FULL | WINDOWS_SERVER_20H2_CORE | LINUX
    operating_system_family = "LINUX"
  
    #Valid Values: X86_64 | ARM64
    cpu_architecture       = "X86_64"
  }

  container_definitions = jsonencode([{
    name  = "sbstestcontainer"
    image = "${data.aws_ecr_repository.nginx_repo.repository_url}:latest"
    portMappings = [
      {
        containerPort = 80,
        hostPort      = 80,
        protocol = "http"
      },
    ]
  }])
}

# ECS Fargate Service
resource "aws_ecs_service" "nginx_service" {
  name            = "FargateSBSService"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = ["subnet-05c3cdb156a3d0b6b", "subnet-00c2fb816269f8dbf", "subnet-0db4ad902a1dc6b4d"]
    security_groups = ["sg-058f54f93cec567e0"]        # Replace with your security group ID
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "nginx_alb" {
  name               = "FargateSBSELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-058f54f93cec567e0"]  # Replace with your ALB security group ID
  subnets            = ["subnet-05c3cdb156a3d0b6b", "subnet-00c2fb816269f8dbf", "subnet-0db4ad902a1dc6b4d"]
}

# ALB Listener
resource "aws_lb_listener" "nginx_alb_listener" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

# ALB Target Group
resource "aws_lb_target_group" "nginx_target_group" {
  name        = "FargateSBSTG"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-089e57f234909bb70"
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "nginx_alb_rule" {
  listener_arn = aws_lb_listener.nginx_alb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}