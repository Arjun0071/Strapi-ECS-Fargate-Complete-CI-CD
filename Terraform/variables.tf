# AWS Region
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

# ECR image info
variable "image_name" {
  type        = string
  description = "ECR repository name for the Strapi container"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag to deploy (e.g., commit SHA)"
}

# Optional default username for RDS
variable "rds_username" {
  type    = string
  default = "strapi_user"
}
