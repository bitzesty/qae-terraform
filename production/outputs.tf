output "address" {
  value = "${aws_elb.production_load_balancer.dns_name}"
}
