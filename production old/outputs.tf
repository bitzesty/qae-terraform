output "address" {
  value = "${aws_elb.production_load_balancer.dns_name}"
}
output "lb_id" {
  value = "${aws_elb.production_load_balancer.id}"
}
# output "virus_scanner_elastic_ip" {
#   value = "${aws_eip.virus_scanner_elastic_ip.public_ip}"
# }
