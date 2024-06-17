# Workshop terraform analytics module
Intro on IaC, terraform, and analytics archi used for the workshop
## 1. Setting up the terraform state
terraform init
terraform fmt
terraform plan
terraform apply

## 2. Creating the analytics module
Module will watch an S3 bucket, so let's create the bucket first
we can use the existing module for it 

Create file called analytics.tf in main folder
module "example_3" {
  source         = "./modules/analytics"
  workload_name = "event_processing"
  s3_arn = "arn"
}


## 3. Using the analytics module
Upload a given file to bucket