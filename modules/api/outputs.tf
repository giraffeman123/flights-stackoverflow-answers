output "alb_dns" {
  description = "application load balancer DNS"
  value       = aws_alb.alb.dns_name
}

output "alb_sg" {
  description = "application load balancer security group id"
  value       = aws_security_group.alb_sg.id
}

output "ec2s_sg" {
  description = "security group of ec2 instances in auto-scaling group"
  value       = aws_security_group.ec2_sg.id  
}