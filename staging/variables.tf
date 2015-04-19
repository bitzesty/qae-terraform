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
  default = "ami-934023e4"
}
variable "postgres_password" {}
variable "ec2_instance_type" {
  default = "t2.medium"
}
variable "user_data" {
  default = "./../settings/user_data.sh"
}

# VIRUS SCANNER VARIABLES
variable "virus_scanner_aws_ami" {
  default = "ami-1940236e"
}
variable "virus_scanner_instance_type" {
  default = "m1.small"
}
