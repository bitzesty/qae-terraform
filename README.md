# QAE Terraform scripts

## GETTING STARTED

1) Install terraform from https://terraform.io/downloads.html

2) Setup necessary packages for AWS CLI
```
$ sudo apt-get install jq
$ sudo apt-get install awscli
```

3) Setup aws credentials
```
$ aws configure
=>
AWS Access Key ID [None]: <AWS_ACCESS_ID>
AWS Secret Access Key [None]: <AWS_SECRET_ACCESS_KEY>
Default region name [None]: eu-west-1
Default output format [None]:
```

4) Clone app
```
$ terraform init git@github.com:bitzesty/qae-terraform.git
```

5) Generate new AWS key pair (or if you already have one - you can just put .pem to ssh_keys directory)
```
$ aws ec2 --region <YOUR REGION (ex: us-east-1)> create-key-pair --key-name qae | jq -r ".KeyMaterial" > ssh_keys/qae.pem

$ chmod 400 ssh_keys/qae.pem
```
New ssh pem file will be generated to ssh_keys/qae.pem.

6) Make a Plan
```
$ terraform plan -var 'key_name=qae' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae.pem'
```

7) Build Infrastructure

```
$ terraform apply -var 'key_name=qae' -var 'key_path=/<ABSOLUTE PATH TO ROOT OF THIS FOLDER>/ssh_keys/qae.pem'
```

```
Outputs:

  address = terraform-example-elb-419196096.us-west-2.elb.amazonaws.com
```

The output above is truncated, but Terraform did a few things for us here:

- Created a security group allowing SSH and HTTP/HTTPS access
- Created 2 EC2 instances from the Ubuntu 14.10 AMI
- Created an ELB instance and used the our EC2 instances as its backend
- Printed the ELB public DNS address in the Outputs section
- Saved the state of your infrastructure in a terraform.tfstate file

You should be able to open the ELB public address in a web browser and see "Welcome to Nginx!" (note: this may take a minute or two after initialization in order for the ELB health check to pass).

8) Review Infrastructure
```
$ terraform show
```
