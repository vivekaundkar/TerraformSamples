Assumption
Docker image is deployed to ECR
I have deployed it to
239338699850.dkr.ecr.ap-southeast-2.amazonaws.com/vivekrepo:latest
Please refer below github repo to push ECR image
https://github.com/vivekaundkar/sbsappFargePipeline 

Once ECR repo is deployed this github repo can be used to
Create a Fargate Cluster, Service, Task definition and deploy above specified ECR image into this cluster
to use this repo from root run below commands
Terraform init
terraform apply

If you want to destroy cluster run
terraform destroy

As a pre requisite you will need Terraform and AWS CLI installed and configure on your local machine or build agent.

This repo uses 2 S3 buckets
sbs-tfstate-bucket - to store TF state
sbsimages - To store images needed by container
Dynamo DB table terraform-lock-table was already created


It creates all required IAM roles for Fargate cluster and gives needed permissions
