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

# Ubuntu Server 14.04 LTS (PV), SSD Volume Type - ami-84562dec
# Ubuntu Server 14.04 LTS (PV),EBS General Purpose (SSD) Volume Type. Support available from Canonical (http://www.ubuntu.com/cloud/services).
# Root device type: ebs Virtualization type: paravirtual
variable "aws_ami" {
  default = "ami-84562dec"
}
