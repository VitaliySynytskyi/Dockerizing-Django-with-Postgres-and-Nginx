locals {
  ssh_user         = "ubuntu"
  key_name         = "public"
  private_key_path = "public.pem"
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_ecr_repository" "my_repo" {
  name                 = "my-docker-repo"
  image_tag_mutability = "MUTABLE"
}

output "ecr_url" {
  value = aws_ecr_repository.my_repo.repository_url
}

# Create an IAM role
resource "aws_iam_role" "ecr" {
  name = "ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Adding a policy for the IAM role that allows access to the ECR
resource "aws_iam_policy" "ecr" {
  name        = "ecr-policy"
  description = "Access to ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Join the policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecr" {
  policy_arn = aws_iam_policy.ecr.arn
  role       = aws_iam_role.ecr.name
}

resource "aws_iam_instance_profile" "ec2-profile" {
  role = aws_iam_role.ecr.name
}

resource "aws_instance" "my_ec2_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.for_public_ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2-profile.name
  key_name                    = local.key_name
}

resource "aws_security_group" "for_public_ec2" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"

  dynamic "ingress" {
    for_each = ["80", "22"]
    content {
      description = "HTTP, SSH ports"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "docker_setup" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce",
      "sudo service docker start",
      "sudo usermod -a -G docker ubuntu",
      "sudo systemctl enable docker.service",
      "sudo apt-get install -y docker-compose",
      "sudo apt-get install awscli -y",
      "sudo aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 301581196284.dkr.ecr.us-east-1.amazonaws.com",
      "sudo mkdir nginx",
    ]
  }
  provisioner "file" {
    content     = file("docker-compose.yml")
    destination = "/home/ubuntu/docker-compose.yml"
  }
  provisioner "file" {
    content     = file("nginx/Dockerfile")
    destination = "/home/ubuntu/Dockerfile"
  }
  provisioner "file" {
    content     = file("nginx/nginx.conf")
    destination = "/home/ubuntu/nginx.conf"
  }

    provisioner "remote-exec" {
    inline = [
      "sudo mv Dockerfile nginx/Dockerfile",
      "sudo mv nginx.conf nginx/nginx.conf",
      "docker compose up -d"
    ]
    }
  depends_on = [aws_instance.my_ec2_instance]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("public.pem")
    host        = aws_instance.my_ec2_instance.public_ip
  }
}

