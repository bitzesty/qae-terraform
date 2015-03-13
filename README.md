## QAE Terraform scripts

### GETTING STARTED

#### 1) Install terraform from https://terraform.io/downloads.html

#### 2) Setup AWS CLI environment

2.1) [INSTALL AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

2.2) Setup necessary packages for AWS CLI
```
$ sudo apt-get install jq
$ sudo apt-get install awscli
```

2.3) Setup aws credentials
```
$ aws configure
=>
AWS Access Key ID [None]: <AWS_ACCESS_ID>
AWS Secret Access Key [None]: <AWS_SECRET_ACCESS_KEY>
Default region name [None]: eu-west-1
Default output format [None]:
```

#### 3) Clone app
```
$ terraform init git@github.com:bitzesty/qae-terraform.git
```

#### 4) Generate new AWS key pair (or if you already have one uploaded to AWS EC-2 -> Key Pairs - then you can just put .pem to ssh_keys directory and skip this step)

```
$ aws ec2 --region <YOUR REGION (ex: eu-west-1)> create-key-pair --key-name qae_<ENVIRONMENT> | jq -r ".KeyMaterial" > ssh_keys/qae_<ENVIRONMENT>.pem

$ chmod 400 ssh_keys/qae_<ENVIRONMENT>.pem
```
New ssh pem file will be generated to ssh_keys/qae_<ENVIRONMENT>.pem.

#### 5) Go to environment folder

```
cd staging
# OR
cd production
```

#### 6) Setup necessary variables in /<ENVIRONMENT>/terraform.tfvars
You can user example file terraform.tfvars.example
```
access_key = "<AWS_ACCESS_KEY>"
secret_key = "<AWS_SECRET_KEY>"
aws_region = "eu-west-1"
postgres_password = ""
aws_ami = "<EC2 AMI>" # ami-234ecc54 # Clean Ubuntu 14.10
ec2_instance_type = "<EC2 INSTANCE TYPE>" # For example: m3.large

```

##### NOTE 1:
Enable user_data in main.tf in case if you are using clean AMI images
without NGINX installed - as AWS Auto-Scaling Group does healthy check to HTTP 80 port
and will terminate current instances and populate new
as new instances do not response on healthy checks.

##### NOTE 2:
By default: we use own already provisioned by CHEF AMI image

#### 7) Make a Plan to see how Terraform intends to build the resources you declared.

```
$ terraform plan -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

Staging:
```
$ terraform plan -var 'key_name=qae_staging' -var 'key_path=/home/alkapone/projects/qae-terraform/ssh_keys/qae_staging.pem'
```
Production:
```
$ terraform plan -var 'key_name=qae_production' -var 'key_path=/home/alkapone/projects/qae-terraform/ssh_keys/qae_production.pem'
```

#### 8) Build Infrastructure

```
$ terraform apply -var 'key_name=qae_<ENVIRONMENT>' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae_<ENVIRONMENT>.pem'
```

```
Outputs:

  address = terraform-example-elb-419196096.us-west-2.elb.amazonaws.com
```

The output above is truncated, but Terraform did a few things for us here:

- Created a security group allowing SSH and HTTP/HTTPS access
- Created a security group allowing access to RDS Postgres instance for EC-2 instances
- Created 2 EC2 instances from the Ubuntu 14.10 AMI
- Created an ELB instance and used the our EC2 instances as its backend
- Created Launch Configuration and Auto-scaling group with (2 min and 3 max instances)
- Created private S3 bucket
- Printed the ELB public DNS address in the Outputs section
- Saved the state of your infrastructure in a terraform.tfstate file

#### 9) Review Infrastructure
```
$ terraform show
```

#### 10) Then you can start CHEF provision of instances

##### 10-1) Add your ssh key to server, which you are gonna to provision with CHEF

```
# test connection by .pem key
ssh -i ssh_keys/qae_<ENVIRONMENT>.pem ubuntu@<EC2 INSTANCE IP>

# add your own ssh key
cat ~/.ssh/id_rsa.pub | ssh -i ssh_keys/qae_<ENVIRONMENT>.pem ubuntu@<EC2 INSTANCE IP> 'cat >> ~/.ssh/authorized_keys'
```

##### 10-2) [QAE CHEF PROVISION GUIDE](https://github.com/bitzesty/qae-chef)

#### 11) ADDING OF OTHER AWS SERVICES

Currently Terraform doesn't allow to setup AWS ElasticCache and AWS SQS.
So, we need to add it manually.

##### 11-1) Setup AWS Elastic Cache

##### 11-2) Setup AWS SQS (Message Queue)

