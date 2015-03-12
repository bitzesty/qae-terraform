provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# Our security group to access the instances over SSH and HTTP/ HTTPS
resource "aws_security_group" "staging_web_security_group" {
  name = "StagingWebServerSG"
  description = "Allow HTTP, HTTPS and SSH inbound traffic from anythere and allow all outbound traffic (STAGING)"

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["162.13.181.148/24"]
  }
}

# Our db security group to allow access to RDS for EC-2 instances
resource "aws_security_group" "staging_db_security_group" {
  name = "StagingDBServerSG"
  description = "Allow access to RDS for EC-2 instances (STAGING)"

  # POSTGRESQL access from EC-2 instances
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.staging_web_security_group.id}"]
  }
}

resource "aws_elb" "staging_load_balancer" {
  name = "StagingLoadBalancer"

  availability_zones = ["us-east-1a", "us-east-1e", "us-east-1c"]
  security_groups = ["${aws_security_group.staging_web_security_group.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  # SSL support
  # Uncomment it once SSL certs will be ready
  # listener {
  #   instance_port = 443
  #   instance_protocol = "https"
  #   lb_port = 443
  #   lb_protocol = "https"
  #   ssl_certificate_id = "www.qae.co.uk"
  # }
}

# Preparing RDS Subnet Group
resource "aws_db_subnet_group" "staging_db_subnet_group" {
  name = "staging_db_subnet_group"
  description = "Staging RDS group of subnets"
  # us-east-1a, us-east-1e, us-east-1c
  subnet_ids = ["subnet-729a212b", "subnet-cf551af5", "subnet-1797373c"]
}

# Creating RDS instance
resource "aws_db_instance" "staging_rds_instance" {
  identifier = "stagingrdsinstance"
  allocated_storage = 5
  storage_type = "gp2" # (general purpose SSD)
  multi_az = true
  engine = "postgres"
  engine_version = "9.3.5"
  instance_class = "db.t2.micro"
  name = "qae"
  username = "qae"
  password = "${var.postgres_password}"
  vpc_security_group_ids = ["${aws_security_group.staging_db_security_group.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.staging_db_subnet_group.id}"
  parameter_group_name = "default.postgres9.3"

  # storage_encrypted = true # Uncomment for prod environment
}

# Create Launch Configuration
resource "aws_launch_configuration" "staging_launch_configuration" {
  name = "staging_launch_configuration"
  image_id = "${var.aws_ami}" # TODO: replace with smth else
  instance_type = "${var.ec2_instance_type}"
  security_groups = ["${aws_security_group.staging_web_security_group.name}"]

  # The name of our SSH keypair we created via aws cli
  key_name = "${var.key_name}"
}

#  Configure Auto Scaling group
resource "aws_autoscaling_group" "staging_autoscaling_group" {
  name = "staging_autoscaling_group"
  availability_zones = ["us-east-1a", "us-east-1e", "us-east-1c"]
  max_size = 3
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 2
  force_delete = true
  launch_configuration = "${aws_launch_configuration.staging_launch_configuration.id}"
  load_balancers = ["${aws_elb.staging_load_balancer.name}"]
}

# Create S3 private bucket
resource "aws_s3_bucket" "staging_aws_bucket" {
  bucket = "staginguploadsbucket"
  acl = "private"
}
