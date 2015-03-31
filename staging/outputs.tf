output "address" {
  value = "${aws_elb.staging_load_balancer.dns_name}"
}

output "lb_id" {
  value = "${aws_elb.staging_load_balancer.id}"
}

#output "virus_scanner_elastic_ip" {
#  value = "${aws_eip.staging_virus_scanner_elastic_ip.public_ip}"
#}

