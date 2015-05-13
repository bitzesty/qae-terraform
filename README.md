![Logo](https://raw.githubusercontent.com/bitzesty/qae/master/public/gov.uk_logotype_crown.png) Queen's Awards for Enterprise
---------------------------

"QAE" is the application which powers the application process for the Queen's Awards for Enterprise.

## Setup QAE Servers AWS Amazon Infrastructure Guide

This guide uses [Terraform](https://www.terraform.io/docs/index.html).

* First of all you need to setup necessary tools on local (Terraform, AWS CLI so on).
  Follow instructions in SETUP GUIDE below.

## Setup Guide

#### STEP 1: [Setup Terraform](https://terraform.io/downloads.html)

#### STEP 2: Setup AWS CLI environment

##### Install packages:
```
$ sudo apt-get install awscli jq
```

* [More Information](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

##### Setup AWS credentials:

```
$ aws configure
=>
AWS Access Key ID [None]: <AWS_ACCESS_ID>
AWS Secret Access Key [None]: <AWS_SECRET_ACCESS_KEY>
Default region name [None]: eu-west-1
Default output format [None]:
```

* Ask for Guys about AWS_ACCESS_ID and AWS_SECRET_ACCESS_KEY

#### STEP 3: Setup QAE Terraform app

```
$ terraform init git@github.com:bitzesty/qae-terraform.git
```

## Provision AWS infrastructure from scratch

* Need to setup local env before you start [SETUP GUIDE](https://github.com/bitzesty/qae-terraform#step-1-setup-terraform)
* All operations with Terraform should be executed with providing AWS key pair,
  so that we need to generate AWS key pair at first.

#### STEP 1: Generate new AWS key pair

Generate AWS key pair via awscli (This command will generate and upload new key pair to AWS)
```
$ aws ec2 --region eu-west-1 create-key-pair --key-name qae_<ENVIRONMENT> | jq -r ".KeyMaterial" > ssh_keys/qae_<ENVIRONMENT>.pem
```

Then need to set proper permissions to generated .pem key:
```
$ chmod 400 ssh_keys/qae_<ENVIRONMENT>.pem
```

* Generated pem key would be saved to ssh_keys/qae_ENVIRONMENT.pem.

#### STEP 2: Go to target environment folder

```
$ cd staging
# OR
$ cd production
```

#### STEP 3: Setup variables

##### Setup variables.tf file:

List of possible variables and it's default values declarated in variables.tf. For example:

```
variable "aws_region" {
  description = "AWS region to launch servers."
  default = "eu-west-1" # Ireland is default
}
```

This example sets default region ("eu-west-1") and adds description for this variable.
Default value of this variable can be overriden in terraform.tfvars file.

Most important variables:

```
aws_ami - setting AWS AMI ubuntu image id for QAE app EC-2 instances

# For example:
variable "aws_ami" {
  default = "ami-bb3a58cc"
}
```

```
ec2_instance_type - setting type of EC-2 instance for QAE app

# For example:
variable "ec2_instance_type" {
  default = "m3.large"
}
```

```
load_balancer_ssl_cert_id - setting SSL Certificate of Load Balancer for QAE app

# For example:
variable "load_balancer_ssl_cert_id" {}

* has no default value, so you need to specify it at terraform.tfvars file
```

```
virus_scanner_aws_ami - setting AWS AMI ubuntu image id for Virus Scanner Engine EC-2 instances

# For example:
variable "virus_scanner_aws_ami" {
  default = "ami-33254844"
}
```

```
virus_scanner_instance_type - setting type of EC-2 instance for Virus Scanner Engine

# For example:
variable "virus_scanner_instance_type" {
  default = "m1.small"
}
```

###### * It's worth to double check all used variables in order to make sure that you are going to provision right AWS infrastructure

##### Setup terraform.tfvars file

All private variables we store in terraform.tfvars file, which is in .gitignore
You can use terraform.tfvars.example.
It looks like this:
```
access_key = "<AWS_ACCESS_KEY>"
secret_key = "<AWS_SECRET_KEY>"
aws_region = "eu-west-1"
postgres_password = ""
load_balancer_ssl_cert_id = ""
```

* This file overrides default values in variables.tf

#### STEP 4: Make a Terraform Plan

* NOTE:
  This command will show you all planned actions.
  This command don't run provision scripts on your AWS infrastructure, it just displaying
  all planned actions.
  It's worth to review output of this command before you will run 'terraform apply'.

```
$ terraform plan -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

Staging:
```
$ terraform plan -var 'key_name=qae_staging' -var 'key_path=./../ssh_keys/qae_staging.pem'
```

Production:
```
$ terraform plan -var 'key_name=qae_production_release' -var 'key_path=./../ssh_keys/qae_production_release.pem'
```

#### STEP 5: Provision AWS Infrastructure

* NOTE:
  This command run provision scripts.
  It's worth to review output of this command before you will run 'terraform apply'.

```
$ terraform apply -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

Staging:
```
$ terraform apply -var 'key_name=qae_staging' -var 'key_path=./../ssh_keys/qae_staging.pem'
```

Production:
```
$ terraform apply -var 'key_name=qae_production_release' -var 'key_path=./../ssh_keys/qae_production_release.pem'
```

##### NOTES

###### * Terraform did a few things here:

* Add bunch of security groups
* RDS Postgresql instance
* Private S3 bucket
* Load Balancer (AWS LB), Launch Configuration and Auto-Scaling Group (AWS ASG) with 2 EC-2 instances from clean from the Ubuntu 14.10 AMI for QAE app
* Load Balancer (AWS LB), Launch Configuration and Auto-Scaling Group (AWS ASG) with 1 EC-2 instances from clean from the Ubuntu 14.10 AMI for Virus Scanner Engine

###### * Terraform saves the state of your infrastructure in a terraform.tfstate and terraform.tfstate.backup files (They are in .gitignore).


###### * It's always required to have latest version of terraform.tfstate and terraform.tfstate.backup files in <ENVIRONMENT> folder (staging/ or production/) if you run provisioning of existing AWS infrastructure (not from scratch).

#### STEP 6: Review Infrastructure

```
$ terraform show -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

* This command will display output with your AWS infrastructure, based on terraform.tfstate and terraform.tfstate.backup files.

If you want to refresh information about your Infrastructure, use:

```
$ terraform refresh -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

#### STEP 7: Adding of other AWS Services

* Current version of Terraform doesn't allow to setup AWS SQS.
  Probably, it would be added in future.
  So, we need to add it manually.

##### Setup AWS SQS (Message Queue)

######* We user AWS SQS as a Message Queue for background jobs and delayed mailers [More Information](http://aws.amazon.com/documentation/sqs/)

##### 1) Visit https://eu-west-1.console.aws.amazon.com/sqs/home?region=eu-west-1

##### 2) Add queues

Add 2 queues per ENV:

```
staging_mailers
staging_default
production_mailers
production_default
```

## Provision of existing AWS infrastructure

* Need to setup local env before you start [SETUP GUIDE](https://github.com/bitzesty/qae-terraform#step-1-setup-terraform)

##### IMPORTANT NOTES:

###### * All private variables are located in terraform.tfvars file (which is in .gitignore).

###### * Terraform saves the state of your infrastructure in a terraform.tfstate and terraform.tfstate.backup files (They are in .gitignore).

###### * It's always required to have latest version of terraform.tfvars, terraform.tfstate and terraform.tfstate.backup files in <ENVIRONMENT> folder (staging/ or production/) if you run provisioning of existing AWS infrastructure (not from scratch).

###### * If latest Terraform provision of AWS infrastructure was runned by another person (not by you) - You should ask him to provide you following files and put them in related <ENVIRONMENT> folder (staging/ or production/):

* terraform.tfstate
* terraform.tfstate.backup
* terraform.tfvars

#### Update Terraform scripts with new AWS AMI ids



