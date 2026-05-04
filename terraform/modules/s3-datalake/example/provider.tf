terraform {
  required_providers {
    aws = {
      source                = "localterraform.com/SSC/aws"
      version               = ">=5.0.0, <6.0.0"
      configuration_aliases = [aws.region1]
    }
  }
}

provider "aws" {
  region = "us-east-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account}:role/tfe-role"
  }
}

provider "aws" {
  alias  = "region1"
  region = "us-east-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account}:role/tfe-role"
  }
}
