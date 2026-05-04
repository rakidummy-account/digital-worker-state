terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">=5.0.0, <6.0.0"
      configuration_aliases = [aws.primary]
    }
  }
}

provider "aws" {
  region = "us-east-2"
  assume_role {
    role_arn = "arn:aws:iam::999999999999:role/tfe-role"
  }
}

provider "aws" {
  alias  = "primary"
  region = "us-east-2"
  assume_role {
    role_arn = "arn:aws:iam::999999999999:role/tfe-role"
  }
}
