data "aws_region" "current" {
  provider = aws.region1
}

data "aws_caller_identity" "current" {
  provider = aws.region1
}

data "aws_kms_alias" "account_kms_key" {
  provider = aws.region1
  name     = "alias/aft/account_kms_cmk"
}

data "aws_ssm_parameter" "core_tags" {
  provider = aws.region1
  name     = "/aft/account-request/custom-fields/core_tags"
}

locals {
  core_tags = jsondecode(data.aws_ssm_parameter.core_tags.insecure_value)
}
