################################## Mandatory Data Sources ##################################

data "aws_ssm_parameter" "core_tags" {
  provider = aws.primary
  name     = "/aft/account-request/custom-fields/core_tags"
}

data "aws_kms_alias" "account_kms_key" {
  provider = aws.primary
  name     = "alias/aft/account_kms_cmk"
}

################################## Additional Data Sources ##################################

data "aws_caller_identity" "current" {
  provider = aws.primary
}

data "aws_region" "current" {
  provider = aws.primary
}

################################## Locals ##################################

locals {
  core_tags   = jsondecode(data.aws_ssm_parameter.core_tags.value)
  merged_tags = merge(local.core_tags, var.tags)
  kms_key_arn = var.kms_key_arn == null ? data.aws_kms_alias.account_kms_key.arn : var.kms_key_arn
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
}

################################## IAM Policy Documents - Bucket Policy ##################################

data "aws_iam_policy_document" "deny_non_ssl" {
  provider = aws.primary

  statement {
    sid       = "DenyNonSSLRequests"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.datalake.arn,
      "${aws_s3_bucket.datalake.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

################################## IAM Policy Documents - Assume Role ##################################

data "aws_iam_policy_document" "assume_role" {
  provider = aws.primary

  for_each = var.iam_roles

  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = each.value.trust_principal_arns
    }
  }
}

################################## IAM Policy Documents - Role Policies ##################################

data "aws_iam_policy_document" "role_policy" {
  provider = aws.primary

  for_each = var.iam_roles

  dynamic "statement" {
    for_each = each.value.policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

################################## IAM Policy Documents - CloudTrail Bucket Policy ##################################

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  provider = aws.primary

  count = var.cloudtrail_config != null ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${var.name_prefix}-${var.cloudtrail_config.trail_suffix}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${local.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${var.name_prefix}-${var.cloudtrail_config.trail_suffix}"]
    }
  }
}
