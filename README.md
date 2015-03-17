## QAE Terraform scripts

### GETTING STARTED

#### 1) Install terraform from https://terraform.io/downloads.html

#### 2) Setup AWS CLI environment

2.1) [INSTALL AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

2.2) Setup necessary packages for AWS CLI
```
$ sudo apt-get install awscli jq
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
without NGINX installed - as AWS Auto-Scaling Group does healthy checks to HTTP 80 port
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
$ terraform plan -var 'key_name=qae_staging' -var 'key_path=./../ssh_keys/qae_staging.pem'
```
Production:
```
$ terraform plan -var 'key_name=qae_production' -var 'key_path=./../ssh_keys/qae_production.pem'
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
- Created a secutiry group allowing access to ElasticCache Redis cluster for EC-2 instances
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

##### 10-2) Setup AWS Elastic Cache

1) Visit https://eu-west-1.console.aws.amazon.com/elasticache/home?region=eu-west-1#

2) Setup new Elastic Cache Redis Cluster

Step 1: Select Engine
  - Redis

Step 2: Specify Cluster Details
  - fill "Cluster Name*" (for example: stagingrediscluster)
  - cache.t2.micro (For Staging) and  cache.m1.small (For production)
    * Make sure that you setup in accordance with "QAE server setup" google doc requirements
  - untick "Enable Replication" for staging and tick it for production
  * other fields leave in defaults

Step 3:Configure Advanced Settings
  - VPC Security Group(s) select "StagingECRedisClusterSG" (which was created by Terraform)
  * other fields leave in defaults

3) Put port and host to related [environment (staging / production) node](https://github.com/bitzesty/qae-chef/blob/master/nodes)
in CHEF REPO.
```
"env": {
  ...
  "AWS_ELASTIC_CACHE_REDIS_CLUSTER_PORT": "6379",
  "AWS_ELASTIC_CACHE_REDIS_CLUSTER_HOST": "stagingrediscluster.XXXXXX.amazonaws.com"
},
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



