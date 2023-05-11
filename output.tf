output "ecr_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.my_repo.repository_url
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.frontend.public_ip
}