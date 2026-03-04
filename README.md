## Table of Contents

- [What This Deploys (Final / Complex)](#what-this-deploys-final--complex)
- [Prerequisites](#prerequisites)
- [FOUNDATIONAL TIER](#foundational-tier)
  - [Goal](#goal)
  - [Foundational Folder Setup](#foundational-folder-setup)
  - [FOUNDATIONAL: main.tf (PASTE EXACTLY)](#foundational-maintf-paste-exactly)
  - [FOUNDATIONAL: Deploy Steps](#foundational-deploy-steps)
  - [FOUNDATIONAL: Verify Jenkins UI](#foundational-verify-jenkins-ui)
- [ADVANCED TIER](#advanced-tier)
  - [Goal](#goal-1)
  - [Advanced Folder Setup](#advanced-folder-setup)
  - [ADVANCED: providers.tf (PASTE EXACTLY)](#advanced-providerstf-paste-exactly)
  - [ADVANCED: variables.tf (PASTE EXACTLY)](#advanced-variablestf-paste-exactly)
  - [ADVANCED: terraform.tfvars (PASTE + REPLACE VALUES)](#advanced-terraformtfvars-paste--replace-values)
  - [ADVANCED: main.tf (PASTE EXACTLY)](#advanced-maintf-paste-exactly)
  - [ADVANCED: Deploy Steps](#advanced-deploy-steps)
- [COMPLEX TIER](#complex-tier)
  - [Goal](#goal-2)
  - [COMPLEX: Update main.tf (ADD THESE BLOCKS)](#complex-update-maintf-add-these-blocks)
  - [COMPLEX: Deploy Steps](#complex-deploy-steps)
  - [COMPLEX: Verify IAM Role Access (No Credentials)](#complex-verify-iam-role-access-no-credentials)
- [TEARDOWN (Avoid AWS Charges)](#teardown-avoid-aws-charges)
- [Author](#author)

# AWS Terraform Project: Jenkins Server (Foundational → Advanced → Complex)

This repository documents how to deploy a Jenkins server on AWS using Terraform, completed in three tiers:

1) Foundational (Single main.tf monolith, hardcoded values allowed)
2) Advanced (Refactor: providers.tf + variables.tf + terraform.tfvars, no hardcoding in main.tf)
3) Complex (IAM Role + Instance Profile for secure S3 read/write from EC2 without static credentials)

This README includes all file contents for each tier so the project can be recreated from scratch.

--------------------------------------------------------------------

## What This Deploys (Final / Complex)

- 1 EC2 instance (Ubuntu 22.04) running Jenkins
- Security Group:
  - SSH (22) allowed only from <MY_PUBLIC_IP>/32
  - Jenkins UI (8080) open for browser access
- 1 S3 bucket for Jenkins artifacts (public access blocked)
- IAM policy + role + instance profile:
  - EC2 can List/Get/Put objects to the artifact bucket using role-based access

--------------------------------------------------------------------

## Prerequisites

You need:
- AWS account
- Terraform installed
- AWS CLI installed
- AWS credentials configured locally (aws configure)
- An existing EC2 Key Pair created in AWS (for SSH)

Recommended:
    Terraform v1.5+
    AWS CLI v2

If needed, configure AWS CLI:
    aws configure

You must know these values before you deploy:
- AWS region (example: us-east-1)
- EC2 key pair name (example: terraform-key)
- Your public IP in /32 (example: 203.0.113.10/32)
- A globally unique S3 bucket name (example: jenkins-artifacts-yourname-2026)

NOTE: S3 bucket names must be globally unique across ALL AWS accounts.

--------------------------------------------------------------------

# FOUNDATIONAL TIER
## Goal
Deploy Jenkins on EC2 + Security Group + private S3 bucket using a single monolithic main.tf file with hardcoded values.

## Foundational Folder Setup

Create a new folder (example):
    jenkins-terraform-foundational

Inside the folder, create ONE file:
    main.tf

--------------------------------------------------------------------

## FOUNDATIONAL: main.tf (PASTE EXACTLY)

IMPORTANT: Replace these placeholders before running Terraform:

- `<AWS_REGION>`
- `<KEY_PAIR_NAME>`
- `<MY_PUBLIC_IP>/32`
- `<UNIQUE_BUCKET_NAME>`

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "<AWS_REGION>"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH from my IP and Jenkins web access on 8080"

  ingress {
    description = "SSH from my public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<MY_PUBLIC_IP>/32"]
  }

  ingress {
    description = "Jenkins web access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = "<UNIQUE_BUCKET_NAME>"
}

resource "aws_s3_bucket_public_access_block" "jenkins_artifacts_block" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "<KEY_PAIR_NAME>"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y fontconfig openjdk-17-jre

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ | tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins
EOF

  tags = {
    Name = "jenkins-server"
  }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}
```

--------------------------------------------------------------------

## FOUNDATIONAL: Deploy Steps

From the foundational folder:

1) Initialize:
    terraform init

2) Validate:
    terraform validate

3) Plan:
    terraform plan

4) Apply:
    terraform apply

Terraform will output:
    jenkins_public_ip = "X.X.X.X"

--------------------------------------------------------------------

## FOUNDATIONAL: Verify Jenkins UI

Open in browser:
    http://<EC2_PUBLIC_IP>:8080

You should see "Unlock Jenkins".

Retrieve initial admin password (SSH in first):

1) SSH:
    chmod 400 <your-key>.pem
    ssh -i <your-key>.pem ubuntu@<EC2_PUBLIC_IP>

2) Get password:
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

--------------------------------------------------------------------

# ADVANCED TIER
## Goal
Refactor Terraform so main.tf contains NO hardcoded values.
Create:
- providers.tf
- variables.tf
- terraform.tfvars
and update main.tf to use variables.

## Advanced Folder Setup

You can either:
A) Refactor inside the same repo folder, OR
B) Create a new folder like:
   jenkins-terraform-advanced

For Advanced, you must have these files:
    providers.tf
    variables.tf
    terraform.tfvars
    main.tf

--------------------------------------------------------------------

## ADVANCED: providers.tf (PASTE EXACTLY)

    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }

    provider "aws" {
      region = var.aws_region
    }

--------------------------------------------------------------------

## ADVANCED: variables.tf (PASTE EXACTLY)

    variable "aws_region" {
      description = "AWS region to deploy resources"
      type        = string
    }

    variable "instance_type" {
      description = "EC2 instance type"
      type        = string
    }

    variable "key_pair_name" {
      description = "Existing EC2 key pair name"
      type        = string
    }

    variable "my_ip" {
      description = "Public IP allowed for SSH (use /32)"
      type        = string
    }

    variable "bucket_name" {
      description = "S3 bucket name for Jenkins artifacts (must be globally unique)"
      type        = string
    }

--------------------------------------------------------------------

## ADVANCED: terraform.tfvars (PASTE + REPLACE VALUES)

    aws_region    = "us-east-1"
    instance_type = "t3.micro"
    key_pair_name = "<KEY_PAIR_NAME>"
    my_ip         = "<MY_PUBLIC_IP>/32"
    bucket_name   = "<UNIQUE_BUCKET_NAME>"

--------------------------------------------------------------------

## ADVANCED: main.tf (PASTE EXACTLY)

This is the foundational infrastructure rewritten to use variables (no hardcoding).

    data "aws_ami" "ubuntu" {
      most_recent = true
      owners      = ["099720109477"] # Canonical

      filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
      }
    }

    resource "aws_security_group" "jenkins_sg" {
      name        = "jenkins-sg"
      description = "Allow SSH from my IP and Jenkins web access on 8080"

      ingress {
        description = "SSH from my public IP"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
      }

      ingress {
        description = "Jenkins web access"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

      egress {
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }

    resource "aws_s3_bucket" "jenkins_artifacts" {
      bucket = var.bucket_name
    }

    resource "aws_s3_bucket_public_access_block" "jenkins_artifacts_block" {
      bucket = aws_s3_bucket.jenkins_artifacts.id

      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }

    resource "aws_instance" "jenkins" {
      ami                    = data.aws_ami.ubuntu.id
      instance_type          = var.instance_type
      key_name               = var.key_pair_name
      vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

      user_data = <<-EOF
                  #!/bin/bash
                  apt-get update -y
                  apt-get install -y fontconfig openjdk-17-jre

                  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
                    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
                  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                    https://pkg.jenkins.io/debian-stable binary/ | tee \
                    /etc/apt/sources.list.d/jenkins.list > /dev/null

                  apt-get update -y
                  apt-get install -y jenkins
                  systemctl enable jenkins
                  systemctl start jenkins
                  EOF

      tags = {
        Name = "jenkins-server"
      }
    }

    output "jenkins_public_ip" {
      value = aws_instance.jenkins.public_ip
    }

--------------------------------------------------------------------

## ADVANCED: Deploy Steps

From the advanced folder:

    terraform init
    terraform validate
    terraform plan
    terraform apply

Verify Jenkins again:
    http://<EC2_PUBLIC_IP>:8080

--------------------------------------------------------------------

# COMPLEX TIER
## Goal
Create an IAM Role that allows S3 read/write access for the Jenkins EC2 instance and attach it using an Instance Profile.

This tier adds:
- aws_iam_policy
- aws_iam_role
- aws_iam_role_policy_attachment
- aws_iam_instance_profile
- Update EC2 to attach instance profile

--------------------------------------------------------------------

## COMPLEX: Update main.tf (ADD THESE BLOCKS)

In the ADVANCED main.tf, add these IAM resources (place them after the S3 bucket resources is fine):

    resource "aws_iam_policy" "jenkins_s3_policy" {
      name        = "jenkins-s3-access-policy"
      description = "Allow EC2 instance to read/write Jenkins artifact bucket"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:ListBucket"
            ]
            Resource = aws_s3_bucket.jenkins_artifacts.arn
          },
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "${aws_s3_bucket.jenkins_artifacts.arn}/*"
          }
        ]
      })
    }

    resource "aws_iam_role" "jenkins_role" {
      name = "jenkins-ec2-role"

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

    resource "aws_iam_role_policy_attachment" "jenkins_s3_attach" {
      role       = aws_iam_role.jenkins_role.name
      policy_arn = aws_iam_policy.jenkins_s3_policy.arn
    }

    resource "aws_iam_instance_profile" "jenkins_instance_profile" {
      name = "jenkins-instance-profile"
      role = aws_iam_role.jenkins_role.name
    }

Then update the EC2 resource by adding this line inside aws_instance "jenkins":

    iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name

--------------------------------------------------------------------

## COMPLEX: Deploy Steps

From the complex folder / final repo folder:

    terraform init
    terraform validate
    terraform plan
    terraform apply

--------------------------------------------------------------------

## COMPLEX: Verify IAM Role Access (No Credentials)

SSH to the instance:
    chmod 400 <your-key>.pem
    ssh -i <your-key>.pem ubuntu@<EC2_PUBLIC_IP>

1) Confirm role is attached:
    curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/

Expected output:
    jenkins-ec2-role

2) Confirm AWS CLI exists:
    aws --version

If not installed:
    sudo apt update
    sudo apt install awscli -y

3) Run S3 tests without credentials:

List bucket:
    aws s3 ls s3://<bucket-name>

Upload:
    echo "jenkins s3 role test" > role-test.txt
    aws s3 cp role-test.txt s3://<bucket-name>/

Download:
    rm -f role-test.txt
    aws s3 cp s3://<bucket-name>/role-test.txt .
    cat role-test.txt

Expected output:
    jenkins s3 role test

--------------------------------------------------------------------

# TEARDOWN (Avoid AWS Charges)

Destroy everything:
    terraform destroy

If destroy fails with BucketNotEmpty, delete the object first:
    aws s3 rm s3://<bucket-name>/role-test.txt

Then destroy again:
    terraform destroy

--------------------------------------------------------------------

# Author

Cameron A. Parker
GitHub:   https://github.com/forgisonajeep
LinkedIn: https://www.linkedin.com/in/cameronaparker/
Medium:   https://medium.com/@parker_c_18
