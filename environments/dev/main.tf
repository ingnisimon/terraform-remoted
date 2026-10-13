terraform {
  backend "s3" {
    bucket       = "nigaso-tf-remoted-oct12-backend"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "serverless_app" {
  source = "../../modules/serverless-api"

  environment       = "dev"
  db_read_capacity  = 1
  db_write_capacity = 1
}
