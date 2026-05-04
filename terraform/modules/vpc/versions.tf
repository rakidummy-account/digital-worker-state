terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source                = "localterraform.com/SSC/aws"
      version               = ">=5.0.0, <6.0.0"
      configuration_aliases = [aws.target_region]
    }
  }
}
