data "aws_ssm_parameter" "core_tags" {
  provider = aws.primary
  name     = "/aft/account-request/custom-fields/core_tags"
}

data "aws_kms_alias" "account_kms_key" {
  provider = aws.primary
  name     = "alias/aft/account_kms_cmk"
}

locals {
  core_tags   = jsondecode(data.aws_ssm_parameter.core_tags.value)
  merged_tags = merge(local.core_tags, var.tags)
  kms_key_arn = var.kms_key_arn == null ? data.aws_kms_alias.account_kms_key.arn : var.kms_key_arn
}
