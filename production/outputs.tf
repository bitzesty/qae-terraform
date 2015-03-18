output "address" {
  value = "${aws_elb.production_load_balancer.dns_name}"
}
output "lb_id" {
  value = "${aws_elb.production_load_balancer.id}"
}
