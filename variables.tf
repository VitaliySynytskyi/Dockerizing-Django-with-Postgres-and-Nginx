variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the key"
  type        = string
  default     = "public"
}

variable "private_key_path" {
  description = "Path to the private key"
  type        = string
  default     = "public.pem"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "my-docker-repo"
}