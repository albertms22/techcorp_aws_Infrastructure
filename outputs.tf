output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "web_server_1_private_ip" {
  description = "Private IP address of web server 1"
  value       = aws_instance.web_1.private_ip
}

output "web_server_2_private_ip" {
  description = "Private IP address of web server 2"
  value       = aws_instance.web_2.private_ip
}

output "database_server_private_ip" {
  description = "Private IP address of database server"
  value       = aws_instance.database.private_ip
}

output "alb_url" {
  description = "URL to access the web application through the load balancer"
  value       = "http://${aws_lb.web.dns_name}"
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_eip.bastion.public_ip} OR ssh techcorp@${aws_eip.bastion.public_ip} (password: ${var.server_password})"
  sensitive   = true
}
