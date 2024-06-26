# Workshop terraform analytics module
This workshop is an introduction to a basic analytics module written in Terraform on AWS.

Terraform is an open-source Infrastructure-as-Code tool created by HashiCorp that helps automate the deployment of infrastructure resources in various environments such as cloud platforms and on-premise data centres.

The content of the workshop is divided into 5 sections as follows:
1. Introduction
2. Getting started: follow the steps to access the provisioned account and perform the initial setup of your IDE on Cloud9 and repository
3. Terraform foundations: start setting up your infrastructure by creating the foundations
4. Analytics module: explore the contents analytics module and create your own
5. Consumers: explore potential consumers of the analytics module

The expected duration to complete this workshop is 1 hour. 

There is no prerequisites to taking this workshop though basic knowledge of Infrastructure as Code is helpful. Attendees with limited technical knowledge on AWS and IaC can successfully complete.

## 2. Creating the Cloud9 instance and setting it up

AWS Cloud9 is a cloud-based integrated development environment (IDE) that lets you write, run, and debug your code with just a browser. It includes a code editor, debugger, and terminal. Cloud9 comes pre-packaged with essential tools for popular programming languages, the AWS Command Line Interface (CLI), docker CLI, git and much more pre-installed so you don’t need to install files or configure your laptop for this workshop. This workshop requires use of *nix environment since it uses bash scripts as part of the labs. Cloud9 runs on an Amazon EC2 instance with Amazon Linux 2 by default. Your Cloud9 environment will have access to the same AWS resources as the user with which you logged into the AWS Management Console.

### Setup

1. Go to the AWS Management Console and access the [Cloud9 Dashboard](https://console.aws.amazon.com/cloud9control/home/).

2. Click on the link to open your IDE. 

3. Disable the AWS Managed Temporary Credentials to use the attached role permission and deploy resources with Terraform commands: Click on the gear (preferences) icon in the top right hand corner of the Cloud9 IDE.

4. Click on the AWS Settings tab and toggle the AWS managed temporary credentials to disable it.

5. We also strongly recommend to enable auto-save, in the "Experimental" tab.

### Install terraform and boto3
Check the version of terraform by running `terraform -version`. If not installed, follow these steps to install it:

```
curl --silent --location -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_386.zip"

unzip /tmp/terraform.zip -d /tmp/terraform

sudo chmod +x /tmp/terraform/terraform

sudo mv -v /tmp/terraform/terraform /usr/local/bin/terraform
```

We will be running a python script to generate transactions for our system, so we will need to install boto3 as well:
```
git clone https://github.com/boto/boto3.git
cd boto3
python -m pip install -r requirements.txt
python -m pip install -e .
```
### Clone repository
On Cloud9, access the terminal and clone the git repository:

```
cd ..
git clone https://github.com/chimarz/terraform-analytics-ws
```

From the terminal, move into the repository you previously cloned:
```
cd terraform-analytics-ws
```

This repository contains the required code to kickstart your terraform development on the account. Open the `main.tf` file to explore its contents. 


### Initialize terraform environment
We start by initializing our setup. From the terminal, run:
```
terraform init
```
This will download plugins and set up our modules. 


We then run `terraform plan` to ask Terraform to create a plan for how our resources will be created:
```
terraform plan
```

If we are satisfied with the plan, we can run:
```
terraform apply
```

Once the `terraform apply` command has finished running and no errors are output, we can check the resources created on our AWS account.
You should have a new S3 bucket and a two new DynamoDB tables.

## 3. Create the analytics module

We now create the analytics module.

Open the `modules` folder. Here you can see a few modules we have created for you. Open the `analytics` folder and check out their contents. 

We can now declare the required elements for analytics module by importing our pre-made modules.

In the root directory, create a new file called `analytics.tf`. In this file, we need to include a DynamoDB that will act as source as follows:

```
module "dynamo" {
  source = "./modules/dynamodb"
  table_name = "Assets"
  hash_key   = "tenantId"
  range_key  = "assetId"
}
```

Let's now create the analytics module:

```
module analytics {
    source             = "./modules/analytics"
    workload_name      = "event-processing"
    buffering_interval = 100
}
```

You can choose a workload name of your choice, this will be used as prefix for the resources created within the module. 

### Apply the changes
As we have started using some modules, go back to the terminal and run:
```
terraform init
```
And then
```
terraform fmt
```
to format your terraform file. 

Then validate your syntax:
```
terraform validate
```

You can then create a plan:
```
terraform plan
```

And, if your plan corresponds to your expectations, run:
```
terraform run
```


### Check the results of the apply

Once the `terraform apply` command has finished running and no errors are output, we can check the resources created on our AWS account.
You should have a new S3 bucket and a new DynamoDB table. 


## 4. Generate transactions

In Cloud9, open the terminal and type
```
python dynamo.py
```
 This script will simulate 100 transactions being written to our database and then sent to EventBridge. 

 After the transactions have been generated, we will be able to see them appear both on Firehose and then S3. We can check the inserted transactions on DynamoDB.

 We are now ready to process the transactions using a Glue job:

 1. Open Glue on the AWS console
 2. Select the transactions job
 3. Click "run" and wait for its completion

 The job will read the transactions from the source S3 bucket, transform it to Parquet format and then store it to the sink S3 bucket. 