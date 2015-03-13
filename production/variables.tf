variable "access_key" {}
variable "secret_key" {}
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}
variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}
variable "aws_region" {
  description = "AWS region to launch servers."
  default = "eu-west-1" # Ireland is default
}

# Ubuntu Server 14.04 LTS (HVM), SSD Volume Type - ami-9a562df2
# Ubuntu Server 14.04 LTS (HVM), EBS General Purpose (SSD) Volume Type. Support available from Canonical (http://www.ubuntu.com/cloud/services).
# Root device type: ebs Virtualization type: hvm
variable "aws_ami" {
  default = "ami-234ecc54"
}
variable "postgres_password" {}
variable "ec2_instance_type" {
  default = "m3.large"
}
variable "user_data" {
  default = "./../settings/user_data.sh"
}

