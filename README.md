# Jenkins on AWS with Terraform
### Infrastructure as Code Deployment with IAM Role-Based S3 Artifact Storage

---

## Project Overview

This project demonstrates how to deploy a Jenkins server on AWS using **Terraform**. The infrastructure is provisioned entirely through **Infrastructure as Code (IaC)**, allowing the environment to be consistently recreated across environments and tracked through version control.

The deployment includes:

- An EC2 instance running Jenkins
- A security group allowing Jenkins access on port 8080
- SSH access restricted to a specific IP
- An S3 bucket used for Jenkins artifact storage
- An IAM role attached to the EC2 instance allowing secure S3 access
- Terraform configuration refactored for maintainability and reusability

The project is implemented in three tiers:

1. **Foundational** – Basic Jenkins infrastructure deployment using Terraform  
2. **Advanced** – Refactored Terraform configuration using variables and provider separation  
3. **Complex** – IAM role-based S3 access from the Jenkins EC2 instance  

---

# Prerequisites

Before beginning the project, ensure the following tools and resources are available.

Required:

- AWS Account
- Terraform installed
- AWS CLI installed
- AWS CLI configured with credentials
- SSH key pair created in AWS

Recommended versions:

```
Terraform v1.5+
AWS CLI v2
```

Configure AWS credentials if not already configured:

```
aws configure
```

---

# Repository Structure

```
.
├── main.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── README.md
└── architecture
    └── jenkins-terraform-architecture.png
```

Explanation of files:

- **main.tf** – Defines AWS infrastructure resources  
- **providers.tf** – Terraform AWS provider configuration  
- **variables.tf** – Terraform variable definitions  
- **terraform.tfvars** – Deployment variable values  

---

# Foundational Tier – Jenkins Infrastructure Deployment

The foundational stage deploys the base Jenkins environment using Terraform.

## Infrastructure Created

- EC2 instance in the **default VPC**
- Security group allowing:
  - SSH (22) from your IP
  - Jenkins UI (8080)
- Jenkins installed via bootstrap script
- Private S3 bucket created for artifact storage

---

## Step 1 – Create Terraform Configuration

Create a file called:

```
main.tf
```

This file defines the AWS resources including:

- EC2 instance
- Security group
- S3 bucket
- Jenkins bootstrap script

The EC2 instance uses **user data** to install Jenkins automatically during instance launch.

---

## Step 2 – Initialize Terraform

Inside the project directory run:

```
terraform init
```

This downloads the AWS provider and initializes the Terraform working directory.

---

## Step 3 – Validate the Configuration

```
terraform validate
```

This ensures the Terraform configuration syntax is valid.

---

## Step 4 – Review the Execution Plan

```
terraform plan
```

Terraform will display which AWS resources will be created.

---

## Step 5 – Deploy the Infrastructure

```
terraform apply
```

Terraform will create the infrastructure and output the **public IP address** of the Jenkins server.

---

## Step 6 – Access Jenkins

Open a browser and navigate to:

```
http://<EC2_PUBLIC_IP>:8080
```

You should see the Jenkins setup screen.

---

## Step 7 – Retrieve the Jenkins Admin Password

SSH into the EC2 instance:

```
ssh -i <keypair>.pem ubuntu@<EC2_PUBLIC_IP>
```

Retrieve the initial admin password:

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Use this password to unlock Jenkins in the web interface.

---

# Advanced Tier – Terraform Refactor for Maintainability

The advanced tier improves the Terraform configuration by removing hardcoded values and separating configuration into reusable components.

---

## Refactor Overview

The configuration is updated to include:

- **providers.tf** – AWS provider configuration
- **variables.tf** – Terraform variables
- **terraform.tfvars** – Variable values
- **main.tf** – Infrastructure resources referencing variables

---

## providers.tf

This file configures the AWS provider.

Example:

```
provider "aws" {
  region = var.aws_region
}
```

---

## variables.tf

This file defines all variables used by Terraform.

Variables include:

- AWS region
- instance type
- key pair name
- allowed SSH IP
- S3 bucket name

Example:

```
variable "aws_region" {}
variable "instance_type" {}
variable "key_pair_name" {}
variable "my_ip" {}
variable "bucket_name" {}
```

---

## terraform.tfvars

This file stores the values for deployment.

Example:

```
aws_region    = "us-east-1"
instance_type = "t3.micro"
key_pair_name = "terraform-key"
my_ip         = "X.X.X.X/32"
bucket_name   = "jenkins-artifacts-example"
```

This refactor ensures that **main.tf contains no hardcoded values**, improving portability and reusability.

---

# Complex Tier – Secure IAM Role-Based S3 Access

The complex tier introduces secure authentication between the Jenkins server and the artifact storage bucket.

Instead of using AWS credentials, the EC2 instance uses an **IAM Role with least privilege permissions**.

---

## Infrastructure Added

- IAM Role
- IAM Policy with S3 permissions
- IAM Instance Profile attached to EC2

Permissions granted:

- `s3:ListBucket`
- `s3:GetObject`
- `s3:PutObject`

---

## IAM Role Workflow

```
EC2 Instance
      |
IAM Instance Profile
      |
IAM Role
      |
IAM Policy
      |
S3 Bucket
```

This allows Jenkins to interact with the S3 artifact bucket securely without storing credentials on the server.

---

# Verify IAM Role Access

SSH into the EC2 instance:

```
ssh -i <keypair>.pem ubuntu@<EC2_PUBLIC_IP>
```

Run:

```
aws s3 ls s3://<bucket-name>
```

Upload a test file:

```
echo "jenkins s3 role test" > role-test.txt
aws s3 cp role-test.txt s3://<bucket-name>/
```

Download the file:

```
aws s3 cp s3://<bucket-name>/role-test.txt .
```

Verify contents:

```
cat role-test.txt
```

Successful upload and download confirms the IAM role permissions are working correctly.

---

# Security Configuration

Security group rules:

```
Inbound
SSH (22)      → <MY_PUBLIC_IP>/32
HTTP (8080)   → 0.0.0.0/0
```

S3 bucket configuration:

- Public access blocked
- IAM role authentication only
- Least privilege permissions

---

# Destroy Infrastructure

To prevent unnecessary AWS costs, remove all infrastructure when testing is complete.

```
terraform destroy
```

Terraform will remove all resources created during deployment.

---

# DevOps Concepts Demonstrated

- Infrastructure as Code using Terraform
- Terraform configuration refactoring
- IAM role-based authentication
- Least privilege security model
- Jenkins CI/CD infrastructure deployment
- Artifact storage using Amazon S3
- Infrastructure validation and testing
- Cloud cost governance through infrastructure teardown

---

# Author

Cameron A. Parker  
Cloud / DevOps Engineer

GitHub  
https://github.com/forgisonajeep

LinkedIn  
https://www.linkedin.com/in/cameronaparker/

Medium  
https://medium.com/@parker_c_18
