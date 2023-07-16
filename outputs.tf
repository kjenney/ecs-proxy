output "nlb_dns_name" {
  description = "The DNS name of the NLS"
  value       = aws_lb.my_nlb.dns_name
}

output "first_service_target_group_arn" {
  description = "The ARN of the target group for the ECS service first"
  value       = aws_lb_target_group.first.arn
}

output "second_service_target_group_arn" {
  description = "The ARN of the target group for the ECS service second"
  value       = aws_lb_target_group.second.arn
}

output "first_service_port" {
  description = "The port that ECS service first is on"
  value       = 8080
}

output "second_service_port" {
  description = "The port that ECS service second is on"
  value       = 8081
}