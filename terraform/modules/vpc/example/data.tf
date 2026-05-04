data "aws_region" "current" {
  provider = aws.primary
}

data "aws_caller_identity" "current" {
  provider = aws.primary
}

data "aws_kms_alias" "account_kms_key" {
  provider = aws.primary
  name     = "alias/aft/account_kms_cmk"
}

data "aws_ssm_parameter" "core_tags" {
  provider = aws.primary
  name     = "/aft/account-request/custom-fields/core_tags"
}

locals {
  core_tags = jsondecode(data.aws_ssm_parameter.core_tags.value)
}
