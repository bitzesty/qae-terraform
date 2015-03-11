output "address" {
  value = "${aws_elb.load_balancer.dns_name}"
}
