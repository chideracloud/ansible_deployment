output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}

output "elb_dns_name" {
  value = aws_lb.app_lb.dns_name
}

output "route53_url" {
  value = "http://terraform-test.${var.domain_name}"
}
