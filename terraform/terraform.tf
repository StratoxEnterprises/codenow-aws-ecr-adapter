terraform {
  required_version = ">= 0.13.3"

  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check = true
    bucket                  = "codenow-terraform-ecr-state"
    key                     = "terraform.tfstate"
    region                  = "eu-central-1"
  }

}