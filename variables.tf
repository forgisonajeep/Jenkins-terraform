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
  description = "Public IP address allowed for SSH"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for Jenkins artifacts"
  type        = string
}
