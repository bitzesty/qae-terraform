provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# Our security group to access the instances over SSH and HTTP/ HTTPS
resource "aws_security_group" "production_web_security_group" {
  name = "ProductionWebServerSG"
  description = "Allow HTTP, HTTPS and SSH inbound traffic from anythere and allow all outbound traffic (PRODUCTION)"

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
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our db security group to allow access to RDS for EC-2 instances
resource "aws_security_group" "production_db_security_group" {
  name = "ProductionDBServerSG"
  description = "Allow access to RDS for EC-2 instances (PRODUCTION)"

  # POSTGRESQL access from EC-2 instances
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.production_web_security_group.id}"]
  }
}

resource "aws_elb" "production_load_balancer" {
  name = "ProductionLoadBalancer"

  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  security_groups = ["${aws_security_group.production_web_security_group.id}"]

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
resource "aws_db_subnet_group" "production_db_subnet_group" {
  name = "production_db_subnet_group"
  description = "Production RDS group of subnets"
  # eu-west-1a, eu-west-1b, eu-west-1c
  subnet_ids = ["subnet-f4c17e83", "subnet-75a7772c", "subnet-0800976d"]
}

# Creating RDS instance
resource "aws_db_instance" "production_rds_instance" {
  identifier = "productionrdsinstance"
  allocated_storage = 5
  storage_type = "gp2" # (general purpose SSD)
  multi_az = true
  engine = "postgres"
  engine_version = "9.3.5"
  instance_class = "db.m3.large"
  name = "qae"
  username = "qae"
  password = "${var.postgres_password}"
  vpc_security_group_ids = ["${aws_security_group.production_db_security_group.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.production_db_subnet_group.id}"
  parameter_group_name = "default.postgres9.3"

  storage_encrypted = true # Uncomment for prod environment
}

# Create Launch Configuration
resource "aws_launch_configuration" "production_launch_configuration" {
  name = "production_launch_configuration"
  image_id = "${var.aws_ami}" # TODO: replace with smth else
  instance_type = "${var.ec2_instance_type}"
  security_groups = ["${aws_security_group.production_web_security_group.name}"]

  # The name of our SSH keypair we created via aws cli
  key_name = "${var.key_name}"
}

#  Configure Auto Scaling group
resource "aws_autoscaling_group" "production_autoscaling_group" {
  name = "production_autoscaling_group"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  max_size = 3
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 2
  force_delete = true
  launch_configuration = "${aws_launch_configuration.production_launch_configuration.id}"
  load_balancers = ["${aws_elb.production_load_balancer.name}"]
}

# Create S3 private bucket
resource "aws_s3_bucket" "production_aws_bucket" {
  bucket = "productionuploadsbucket"
  acl = "private"
}
