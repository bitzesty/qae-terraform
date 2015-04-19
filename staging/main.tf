provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# SECURITY GROUPS
# EC-2 instances access over SSH
resource "aws_security_group" "staging_web_security_group" {
  name = "StagingWebServerSG"
  description = "Allow SSH only from Bit Zesty IP range (STAGING)"

  # SSH access from Bit Zesty IP range only
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
  description = "Allow HTTP, HTTPS inbound traffic from Cloudflare only allow all outbound traffic"

  # Cloudflare IPS: https://www.cloudflare.com/ips

  # HTTP access from Cloudflare
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "162.13.181.148/24", #Bit Zesty
      "199.27.128.0/21",
      "173.245.48.0/20",
      "103.21.244.0/22",
      "103.22.200.0/22",
      "103.31.4.0/22",
      "141.101.64.0/18",
      "108.162.192.0/18",
      "190.93.240.0/20",
      "188.114.96.0/20",
      "197.234.240.0/22",
      "198.41.128.0/17",
      "162.158.0.0/15",
      "104.16.0.0/12",
      "172.64.0.0/13"
    ]
  }

  # HTTPS access from Cloudflare
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "162.13.181.148/24", #Bit Zesty
      "199.27.128.0/21",
      "173.245.48.0/20",
      "103.21.244.0/22",
      "103.22.200.0/22",
      "103.31.4.0/22",
      "141.101.64.0/18",
      "108.162.192.0/18",
      "190.93.240.0/20",
      "188.114.96.0/20",
      "197.234.240.0/22",
      "198.41.128.0/17",
      "162.158.0.0/15",
      "104.16.0.0/12",
      "172.64.0.0/13"
    ]
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
    security_groups = [
      "${aws_security_group.staging_web_security_group.id}",
      "${aws_security_group.virus_scanner_staging_http_security_group.id}"
    ]
  }
}

# LOAD BALANCER
resource "aws_elb" "staging_load_balancer" {
  name = "StagingLoadBalancer"

  availability_zones = ["eu-west-1a", "eu-west-1b"]
  security_groups = ["${aws_security_group.staging_lb_security_group.id}"]
  cross_zone_load_balancing = true

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 443
    instance_protocol = "https"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "arn:aws:iam::081077294140:server-certificate/queens-awards-enterprise.service.gov.uk"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 5
    timeout = 5
    target = "HTTPS:443/healthcheck"
    interval = 300
  }
}

# Preparing RDS Subnet Group
resource "aws_db_subnet_group" "staging_db_subnet_group" {
  name = "staging_db_subnet_group"
  description = "Staging RDS group of subnets"
  # eu-west-1a, eu-west-1b
  subnet_ids = ["subnet-f4c17e83", "subnet-75a7772c"]
}

# Creating RDS instance
resource "aws_db_instance" "staging_rds_instance" {
  identifier = "stagingrdsinstance"
  allocated_storage = 10
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

  multi_az = true
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
}

#  Configure Auto Scaling (EU-West-1a | EU-West-1b) group
resource "aws_autoscaling_group" "staging_autoscaling_group" {
  name = "staging_autoscaling_group"
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  max_size = 2
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

#######################################
# VIRUS SCANNER CONFIGURATION | BEGIN #
#######################################

resource "aws_security_group" "virus_scanner_staging_ssh_security_group" {
  name = "VirusScannerStagingSSHSG"
  description = "Allow SSH only from Bit Zesty IP range (STAGING)"

  # SSH access from Bit Zesty IP range only
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["162.13.181.148/24"]
  }
}

# EC-2 instances access over HTTP from LB only
resource "aws_security_group" "virus_scanner_staging_http_security_group" {
  name = "VirusScannerStagingHTTPSG"
  description = "Allow HTTP, HTTPS inbound traffic from LB only"

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.virus_scanner_staging_lb_security_group.id}"]
  }
}

# LOAD BALANCER security group with access over HTTP
resource "aws_security_group" "virus_scanner_staging_lb_security_group" {
  name = "VirusScannerStagingLoadBalancerSG"
  description = "Allow HTTP inbound traffic from Staging servers only allow all outbound traffic"

  # HTTP access from Staging servers
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # This one doesn't work - need to fix it when we will have time
    # For now access from anythere
    # security_groups = ["${aws_security_group.staging_lb_security_group.id}"]
  }
}


# LOAD BALANCER
resource "aws_elb" "virus_scanner_staging_load_balancer" {
  name = "VirusScannerStagingLoadBalancer"

  availability_zones = ["eu-west-1a"]
  security_groups = ["${aws_security_group.virus_scanner_staging_lb_security_group.id}"]
  cross_zone_load_balancing = true

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 5
    timeout = 5
    target = "HTTP:80/healthcheck"
    interval = 300
  }
}

# Create Launch Configuration
resource "aws_launch_configuration" "virus_scanner_staging_launch_configuration" {
  name = "virus_scanner_staging_launch_configuration"
  image_id = "${var.virus_scanner_aws_ami}"
  instance_type = "${var.virus_scanner_instance_type}"
  security_groups = [
    "${aws_security_group.virus_scanner_staging_ssh_security_group.name}",
    "${aws_security_group.virus_scanner_staging_http_security_group.name}"
  ]

  key_name = "${var.key_name}"
}

#  Configure Auto Scaling (EU-West-1a | EU-West-1b) group
resource "aws_autoscaling_group" "virus_scanner_staging_autoscaling_group" {
  name = "virus_scanner_staging_autoscaling_group"
  availability_zones = ["eu-west-1a"]
  max_size = 1
  min_size = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 1
  force_delete = true
  launch_configuration = "${aws_launch_configuration.virus_scanner_staging_launch_configuration.id}"
  load_balancers = ["${aws_elb.virus_scanner_staging_load_balancer.name}"]
}

#####################################
# VIRUS SCANNER CONFIGURATION | END #
#####################################
