# Ansible-Jenkins-Terraform

This project automates the setup of Jenkins, Terraform, and Nginx on an Ubuntu EC2 instance using **Ansible**, **Terraform**, and **Jenkins**. It provisions AWS infrastructure, installs necessary dependencies, and configures Jenkins behind an Nginx reverse proxy. The Jenkins pipeline automates security scanning and testing.

## Project Structure

The project consists of the following files:

- **install_jenkins.yml** - Ansible playbook that installs Jenkins, Terraform, and Nginx.
- **main.tf** - Terraform configuration to provision AWS resources (EC2, IAM, VPC, S3, etc.).
- **jenkins_pipeline.groovy** - Jenkins pipeline configuration for CI/CD automation.
- **s3_backend.tf** - Terraform configuration for S3 state storage and DynamoDB locking.
- **variables.tf** - Terraform variables (AWS region, AMI ID, SSH key path).
- **test_server.py** - Python script that verifies the Jenkins server is running.

## Architecture Overview
![ansible_jenkins_terraform_architecture](https://github.com/user-attachments/assets/44408264-799a-4310-bb90-300aeff018c8)


## Prerequisites

Before running this project, ensure you have the following tools installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [Jenkins](https://www.jenkins.io/download/)
- [Python](https://www.python.org/downloads/)

You will also need an **AWS account** and configured **AWS credentials** for Terraform.

## How to Use

### Step 1: Clone the Repository

```bash
git clone https://github.com/bt00000/ansible-jenkins-terraform.git
cd ansible-jenkins-terraform
```

### Step 2: Configure Terraform

Set up your AWS credentials:

```bash
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
```

Initialize and apply Terraform:

```bash
terraform init
terraform apply -var=ssh_public_key=path_to_your_ssh_public_key.pub -auto-approve
```

Terraform provisions:

- VPC, subnet, security group, IAM roles
- S3 backend for state storage
- EC2 instance for Jenkins

### Step 3: Access Jenkins

Once Terraform completes, access Jenkins using the EC2 public IP:

```bash
http://<JENKINS_PUBLIC_IP>
```

Retrieve the initial Jenkins admin password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Follow the Jenkins setup wizard to install recommended plugins and create an admin user.

### Step 4: Jenkins Configures Nginx

Jenkins runs an **Ansible playbook** to install and configure **Nginx as a reverse proxy**.
After setup, Jenkins is accessible at:

```bash
http://<JENKINS_PUBLIC_IP>
```

### Step 5: Jenkins CI/CD Pipeline

Jenkins runs an automated CI/CD pipeline that includes:

- **Testing (pytest)**: Executes tests in the `tests/` directory.
- **Security Scans (Bandit, Trivy)**: Checks for security vulnerabilities.
- **Deployment**: Configures Nginx and finalizes Jenkins setup.

You can monitor pipeline execution inside the **Jenkins UI**.

### Step 6: Application Deployment

Jenkins automatically deploys the application after successful testing and security scans.
Deployment logs and results are visible in Jenkins UI.

## Security Scanning

This project includes security scanning in the Jenkins pipeline:

- **Bandit (Python security scanner)**: Checks for vulnerabilities in the Python codebase.
- **Trivy (Container & filesystem vulnerability scanner)**: Scans for high/critical security issues.

## Future Improvements

- Enhance IAM policies for least privilege.
- Integrate Docker for containerized builds.
- Add TLS/SSL to secure Jenkins with HTTPS.

