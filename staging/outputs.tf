output "address" {
  value = "${aws_elb.staging_load_balancer.dns_name}"
}
