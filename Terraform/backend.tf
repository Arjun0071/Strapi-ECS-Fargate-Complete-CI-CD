terraform {
  backend "s3" {
    bucket         = "terraform-state-arjuns-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
  }
}
