output "address" {
  value = "${aws_elb.bzstaging_load_balancer.dns_name}"
}

output "lb_id" {
  value = "${aws_elb.bzstaging_load_balancer.id}"
}
