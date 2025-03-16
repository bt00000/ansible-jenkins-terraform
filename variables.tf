variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-0e1bed4f06a3b463d" # Ubuntu 22.04 LTS (x86_64)
}

variable "ssh_public_key" {
  description = "Path to the SSH public key"
  default     = "" # Default is empty, so we can pass it dynamically
}

