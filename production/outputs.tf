output "address" {
  value = "${aws_elb.production_load_balancer.dns_name}"
}

output "vs_address" {
  value = "${aws_elb.virus_scanner_production_load_balancer.dns_name}"
}

output "lb_id" {
  value = "${aws_elb.production_load_balancer.id}"
}

output "vs_id" {
  value = "${aws_elb.virus_scanner_production_load_balancer.id}"
}

