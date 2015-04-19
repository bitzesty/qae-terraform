output "address" {
  value = "${aws_elb.staging_load_balancer.dns_name}"
}

output "lb_id" {
  value = "${aws_elb.staging_load_balancer.id}"
}

output "vs_lb" {
  value = "${aws_elb.virus_scanner_staging_load_balancer.id}"
}
