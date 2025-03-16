terraform {
  backend "s3" {
    bucket         = "jenkins-terraform-state-bucket-bt00000"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Generate SSH Key Pair for Jenkins
resource "aws_key_pair" "deployer" {
  key_name   = "jenkins-ansible-key"
  public_key = file(var.ssh_public_key != "" ? var.ssh_public_key : "~/.ssh/id_rsa.pub")
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg-"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jenkins UI
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Jenkins-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "Jenkins-Internet-Gateway"
  }
}

# Public Subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Jenkins-Public-Subnet"
  }
}

# Route Table
resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "Jenkins-Route-Table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "jenkins_rta" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

# IAM Role for Jenkins EC2 Instance
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "Jenkins Terraform IAM Role" }

  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

# IAM Policy for Jenkins Access
resource "aws_iam_policy" "jenkins_policy" {
  name        = "jenkins-terraform-policy"
  description = "Grants Jenkins full IAM, EC2, S3, and DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "iam:*", Resource = "*" },
      { Effect = "Allow", Action = "ec2:*", Resource = "*" },
      { Effect = "Allow", Action = "s3:*", Resource = "*" },
      { Effect = "Allow", Action = "dynamodb:*", Resource = "*" }
    ]
  })

  lifecycle {
    ignore_changes = [policy]
  }
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "jenkins_policy_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins_instance" {
  ami                         = var.ami_id
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.jenkins_subnet.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name

  # Ensure Jenkins starts on boot
  user_data = <<-EOF
              #!/bin/bash
              sudo systemctl enable jenkins
              sudo systemctl restart jenkins
              EOF

  lifecycle {
    ignore_changes = [instance_type, ami]
  }

  tags = { Name = "Jenkins-Server" }
}

# Output Jenkins Public IP
output "instance_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}
