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
  default = "ami-a2c98cd5" # Ubuntu Server 14.04 LTS (HVM), provisioned by CHEF scripts
}
variable "postgres_password" {}
variable "ec2_instance_type" {
  default = "t2.small"
}
variable "load_balancer_ssl_cert_id" {}
