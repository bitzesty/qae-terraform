provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# SECURITY GROUPS
# EC-2 instances access over SSH
resource "aws_security_group" "staging_web_security_group" {
  name = "StagingWebServerSG"
  description = "Allow SSH only from Bitzesty IP range (STAGING)"

  # SSH access from Bitzesty IP range only
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["162.13.181.148/24"]
  }
}

# EC-2 instances access over HTTP/ HTTPS from LB only
resource "aws_security_group" "staging_web_http_security_group" {
  name = "StagingWebServerHTTPSG"
  description = "Allow HTTP, HTTPS inbound traffic from LB only"

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.staging_lb_security_group.id}"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.staging_lb_security_group.id}"]
  }
}

# LOAD BALANCER security group with access over HTTP/ HTTPS
resource "aws_security_group" "staging_lb_security_group" {
  name = "StagingLoadBalancerSG"
  description = "Allow HTTP, HTTPS inbound traffic from anythere and allow all outbound traffic"

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
}

# DB security group to allow access to RDS for EC-2 instances
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

# Redis security group to allow access to ElasticCache Redis cluster for EC-2 instances
resource "aws_security_group" "staging_eccluster_security_group" {
  name = "StagingECRedisClusterSG"
  description = "Allow access to ElasticCache Redis cluster for EC-2 instances (STAGING)"

  # ElasticCache Redis cluster from EC-2 instances
  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = ["${aws_security_group.staging_web_security_group.id}"]
  }
}

# LOAD BALANCER
resource "aws_elb" "staging_load_balancer" {
  name = "StagingLoadBalancer"

  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  security_groups = ["${aws_security_group.staging_lb_security_group.id}"]
  cross_zone_load_balancing = true

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }
}

# Preparing RDS Subnet Group
resource "aws_db_subnet_group" "staging_db_subnet_group" {
  name = "staging_db_subnet_group"
  description = "Staging RDS group of subnets"
  # eu-west-1a, eu-west-1b, eu-west-1c
  subnet_ids = ["subnet-f4c17e83", "subnet-75a7772c", "subnet-0800976d"]
}

# Creating RDS instance
resource "aws_db_instance" "staging_rds_instance" {
  identifier = "stagingrdsinstance"
  allocated_storage = 5
  storage_type = "gp2" # (general purpose SSD)
  engine = "postgres"
  engine_version = "9.3.5"
  instance_class = "db.t2.micro"
  name = "qae"
  username = "qae"
  password = "${var.postgres_password}"
  vpc_security_group_ids = ["${aws_security_group.staging_db_security_group.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.staging_db_subnet_group.id}"
  parameter_group_name = "default.postgres9.3"
}

# Create Launch Configuration
resource "aws_launch_configuration" "staging_launch_configuration" {
  name = "staging_launch_configuration"
  image_id = "${var.aws_ami}" # TODO: replace with smth else
  instance_type = "${var.ec2_instance_type}"
  security_groups = [
    "${aws_security_group.staging_web_security_group.name}",
    "${aws_security_group.staging_web_http_security_group.name}"
  ]

  # The name of our SSH keypair we created via aws cli
  key_name = "${var.key_name}"

  # Enable user_data in case if you are using clean AMI images
  # without NGINX installed - as AWS Auto-Scaling Group
  # does healthy check to HTTP 80 port
  # and will terminate current instances and populate new
  # as new instances do not response on healthy checks
  # user_data = "${file(var.user_data)}"
}

#  Configure Auto Scaling group
resource "aws_autoscaling_group" "staging_autoscaling_group" {
  name = "staging_autoscaling_group"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
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

# VIRUS SCANNER CONFIGURATION

# Virus scanner security group to access the instances over SSH
resource "aws_security_group" "staging_virus_scanner_ssh_security_group" {
  name = "StagingVirusScannerSSHSG"
  description = "Allow SSH only from Bitzesty IP range (STAGING)"

  # SSH access from Bitzesty IP range only
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["162.13.181.148/24"]
  }
}

# Virus scanner access over HTTP/ HTTPS from LB and EC-2 instances only
resource "aws_security_group" "staging_virus_scanner_http_security_group" {
  name = "StagingVirusScannerHTTPSG"
  description = "Allow HTTP, HTTPS inbound traffic from LB and EC-2 instances only"

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.staging_lb_security_group.id}",
      "${aws_security_group.staging_web_security_group.id}"
    ]
  }

  # HTTPS access from anywhere
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.staging_lb_security_group.id}",
      "${aws_security_group.staging_web_security_group.id}"
    ]
  }
}

# Virus Scanner EC-2 instance
resource "aws_instance" "staging_virus_scanner_instance" {
  ami = "${var.virus_scanner_aws_ami}"
  instance_type = "${var.virus_scanner_instance_type}"
  availability_zone = "eu-west-1a"

  key_name = "${var.key_name}"

  security_groups = [
    "${aws_security_group.staging_virus_scanner_http_security_group.id}",
    "${aws_security_group.staging_virus_scanner_ssh_security_group.id}"
  ]

  tags {
    Name = "StagingVirusScanner"
  }
}

# Assign Elastic IP to Virus Scanner EC-2 instance
resource "aws_eip" "staging_virus_scanner_elastic_ip" {
  instance = "${aws_instance.staging_virus_scanner_instance.id}"
  vpc = true
}
