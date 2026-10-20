terraform {
  backend "s3" {
    bucket       = "nigaso-tf-remoted-oct12-backend"
    key          = "prod/terraform.tfstate"
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

  environment       = "prod"
  db_read_capacity  = 5
  db_write_capacity = 5
}
output "prod_api_url" {
  value = module.serverless_app.api_endpoint
}
