# Jenkins on AWS with Terraform  
## Infrastructure as Code Deployment with IAM Role-Based S3 Artifact Storage

---

## Project Overview

This project demonstrates how to deploy a Jenkins server on AWS using **Terraform**. The infrastructure is defined entirely through **Infrastructure as Code (IaC)**, enabling consistent, repeatable, and version-controlled deployments.

The environment provisions:

• An EC2 instance running Jenkins  
• A security group allowing Jenkins access on port 8080  
• An IAM role attached to the EC2 instance  
• An S3 bucket used for Jenkins artifact storage  
• Least-privilege IAM policies for secure S3 access  

The project was implemented in three stages:

1. Foundational Infrastructure Deployment  
2. Terraform Refactor for Maintainability  
3. Secure IAM Role-Based S3 Artifact Access  

---

## Architecture Diagram

![alt text](image.png)

---

## Prerequisites

Before deploying the infrastructure ensure the following tools are installed and configured.

Required:

• AWS Account  
• Terraform  
• AWS CLI  
• SSH Key Pair  

Recommended versions:

```
Terraform v1.5+
AWS CLI v2
```

---

## Repository Structure

```
.
├── main.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── .gitignore
└── docs
    ├── foundational-notes.md
    ├── advanced-notes.md
    └── complex-notes.md
```

Explanation of files:

- **main.tf** – Infrastructure resources  
- **providers.tf** – AWS provider configuration  
- **variables.tf** – Terraform variable definitions  
- **terraform.tfvars** – Variable values used for deployment  

---

## Deployment Steps

### 1. Clone the Repository

```
git clone https://github.com/forgisonajeep/Jenkins-terraform
cd Jenkins-terraform
```

---

### 2. Initialize Terraform

```
terraform init
```

This downloads the required providers and initializes the Terraform working directory.

---

### 3. Validate Terraform Configuration

```
terraform validate
```

Ensures the Terraform configuration is syntactically correct before deployment.

---

### 4. Review the Execution Plan

```
terraform plan
```

This command shows which infrastructure resources Terraform will create or modify.

---

### 5. Deploy the Infrastructure

```
terraform apply
```

Terraform provisions the AWS infrastructure and outputs the public IP address of the Jenkins server.

---

## Access Jenkins

Once the deployment completes, Jenkins can be accessed through the EC2 public IP.

```
http://<EC2_PUBLIC_IP>:8080
```

Jenkins requires an initial administrator password during first login.

Retrieve the password from the EC2 instance:

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Verify IAM Role Access to S3

SSH into the EC2 instance and confirm that the instance can access the artifact bucket using the IAM role.

List bucket contents:

```
aws s3 ls s3://<bucket-name>
```

Upload a test artifact:

```
echo "jenkins s3 role test" > role-test.txt
aws s3 cp role-test.txt s3://<bucket-name>/
```

Download the artifact:

```
aws s3 cp s3://<bucket-name>/role-test.txt .
```

Confirm the file contents:

```
cat role-test.txt
```

Successful upload and download confirms that the IAM role permissions are functioning correctly.

---

## Security Configuration

Security Group rules:

```
Inbound
SSH (22)   → <MY_PUBLIC_IP>/32
HTTP (8080) → 0.0.0.0/0
```

S3 bucket configuration:

• Public access blocked  
• IAM role used for authentication  
• Least privilege permissions applied  

---

## Destroy Infrastructure

To avoid unnecessary AWS charges, remove all infrastructure when testing is complete.

```
terraform destroy
```

Terraform will delete all resources created during deployment.

---

## Key DevOps Concepts Demonstrated

• Infrastructure as Code using Terraform  
• AWS IAM role-based authentication  
• Least privilege security model  
• Jenkins CI/CD infrastructure deployment  
• Artifact storage using Amazon S3  
• Infrastructure validation and testing  
• Cloud cost governance through infrastructure teardown  

---

## Author

Cameron A. Parker  
Cloud / DevOps Engineer

GitHub  
https://github.com/forgisonajeep

LinkedIn  
https://www.linkedin.com/in/cameronaparker/

Medium  
https://medium.com/@parker_c_18
