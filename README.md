![Logo](https://raw.githubusercontent.com/bitzesty/qae/master/public/gov.uk_logotype_crown.png) Queen's Awards for Enterprise
---------------------------

"QAE" is the application which powers the application process for the Queen's Awards for Enterprise.

## Setup QAE Servers AWS Amazon Infrastructure Guide

This guide uses [Terraform](https://www.terraform.io/docs/index.html).

* First of all you need to setup necessary tools on local (Terraform, AWS CLI so on).

## Setup Guide

#### STEP 1: [Setup Terraform](https://terraform.io/downloads.html)

#### STEP 2: Setup AWS CLI environment

##### Install packages
```
$ sudo apt-get install awscli jq
```

* [More Information](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

##### Setup AWS credentials

```
$ aws configure
=>
AWS Access Key ID [None]: <AWS_ACCESS_ID>
AWS Secret Access Key [None]: <AWS_SECRET_ACCESS_KEY>
Default region name [None]: eu-west-1
Default output format [None]:
```

* Ask for Guys about <AWS_ACCESS_ID> and <AWS_SECRET_ACCESS_KEY>

#### STEP 3: Setup QAE - Terraform app

```
$ terraform init git@github.com:bitzesty/qae-terraform.git
```



## Provision AWS infrastructure from scratch

* Need to setup local env before you start [SETUP GUIDE]()
* All operations with Terraform should be executed with providing AWS key pair,
  so that we need to generate AWS key pair at first.

#### STEP 1: Generate new AWS key pair

Generate AWS key pair via awscli (This command will generate and upload new key pair to AWS)
```
$ aws ec2 --region eu-west-1 create-key-pair --key-name qae_<ENVIRONMENT> | jq -r ".KeyMaterial" > ssh_keys/qae_<ENVIRONMENT>.pem
```


Add proper permissions to generate .pem key
```
$ chmod 400 ssh_keys/qae_<ENVIRONMENT>.pem
```

* Generated pem key would be saved to ssh_keys/qae_<ENVIRONMENT>.pem.

#### STEP 2: Go to target environment folder

```
cd staging
# OR
cd production
```

#### STEP 3: Setup variables

* Terraform saves all variables in terraform.tfvars file, which is in .gitignore

You can use terraform.tfvars.example as example.
It looks like this:
```
access_key = "<AWS_ACCESS_KEY>"
secret_key = "<AWS_SECRET_KEY>"
aws_region = "eu-west-1"
postgres_password = ""
```

* List of possible variables and it's default values are in variables.tf:

```
variable "aws_region" {
  description = "AWS region to launch servers."
  default = "eu-west-1" # Ireland is default
}
```
This example sets default region ("eu-west-1") and adds description for this variable.
Default value of this variable can be overriden in terraform.tfvars file.

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

###### Terraform did a few things here:

* Add bunch of security groups
* RDS Postgresql instance
* Private S3 bucket
* Load Balancer (AWS LB), Launch Configuration and Auto-Scaling Group (AWS ASG) with 2 EC-2 instances from clean from the Ubuntu 14.10 AMI for QAE app
* Load Balancer (AWS LB), Launch Configuration and Auto-Scaling Group (AWS ASG) with 1 EC-2 instances from clean from the Ubuntu 14.10 AMI for Virus Scanner Engine

###### Terraform saves the state of your infrastructure in a terraform.tfstate and terraform.tfstate.backup files (They are in .gitignore).


###### It's always required to have latest version of terraform.tfstate and terraform.tfstate.backup files in <ENVIRONMENT> folder (staging/ or production/) if you run provisioning existing AWS infrastructure (not from scratch).

#### STEP 6: Review Infrastructure

```
$ terraform show -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

* This command will display output with your AWS infrastructure, based on terraform.tfstate and terraform.tfstate.backup files.

If you want to refresh information about your Infrastructure, use:

```
$ terraform refresh -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```


## Provision of existing AWS infrastructure

* Need to setup local env before you start [SETUP GUIDE]()

#### Update Terraform scripts with new AWS AMI ids






#### 9) Review Infrastructure


#### 10) ADDING OF OTHER AWS SERVICES

Currently Terraform doesn't allow to setup AWS ElasticCache and AWS SQS.
So, we need to add it manually.

##### 10-1) Setup AWS SQS (Message Queue)

1) Visit https://eu-west-1.console.aws.amazon.com/sqs/home?region=eu-west-1#

2) Add 2 queues per ENV:
```
- staging_mailers
- staging_default
- production_mailers
- production_default
```


#### 11) Then you can start CHEF provision of instances

##### NOTE 1
You need to do CHEF provision only in 2 cases:
1) if you starting with clean Ubuntu AMI
2) if you need to make some global changes (install some packeges, updated configuration so on) - not deploys

##### NOTE 2
By default we already have prepared AMI with all necessary packages and configuration

##### 11-1) Add your ssh key to server, which you are gonna to provision with CHEF

```
# test connection by .pem key
ssh -i ssh_keys/qae_<ENVIRONMENT>.pem ubuntu@<EC2 INSTANCE IP>

# add your own ssh key
cat ~/.ssh/id_rsa.pub | ssh -i ssh_keys/qae_<ENVIRONMENT>.pem ubuntu@<EC2 INSTANCE IP> 'cat >> ~/.ssh/authorized_keys'
```

##### 11-2) [QAE CHEF PROVISION GUIDE](https://github.com/bitzesty/qae-chef)



