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

# Ubuntu Server 14.04 LTS (HVM), provisioned by CHEF scripts
variable "aws_ami" {
  default = "ami-258fec52"
}
variable "postgres_password" {}
variable "ec2_instance_type" {
  default = "m3.large"
}

# VIRUS SCANNER VARIABLES
variable "virus_scanner_aws_ami" {
  default = "ami-5da23a2a"
}
variable "virus_scanner_instance_type" {
  default = "m1.small"
}



