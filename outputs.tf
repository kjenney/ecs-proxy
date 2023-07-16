output "nlb_dns_name" {
  description = "The DNS name of the NLS"
  value       = aws_lb.my_nlb.dns_name
}

output "first_service_port" {
  description = "The port that ECS service first is on"
  value       = 8080
}

output "second_service_port" {
  description = "The port that ECS service second is on"
  value       = 8081
}