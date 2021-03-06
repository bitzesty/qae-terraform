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
variable "aws_ami" {
  default = "ami-9d9dbdea" # Ubuntu Server 14.04 LTS (HVM), provisioned by CHEF scripts
}
variable "postgres_password" {}
variable "ec2_instance_type" {
  default = "m3.large"
}
variable "load_balancer_ssl_cert_id" {}

# VIRUS SCANNER VARIABLES
variable "virus_scanner_aws_ami" {
  default = "ami-239ebe54"
}
variable "virus_scanner_instance_type" {
  default = "m1.small"
}



