################################## S3 Data Lake Bucket (step_01) ##################################

resource "aws_s3_bucket" "datalake" {
  provider = aws.target_region

  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags
}

################################## S3 Data Lake Versioning (step_01) ##################################

resource "aws_s3_bucket_versioning" "datalake" {
  provider = aws.target_region

  bucket = aws_s3_bucket.datalake.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

################################## S3 Data Lake Encryption (step_01) ##################################

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  provider = aws.target_region

  bucket = aws_s3_bucket.datalake.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

################################## S3 Data Lake Public Access Block (step_01) ##################################

resource "aws_s3_bucket_public_access_block" "datalake" {
  provider = aws.target_region

  bucket = aws_s3_bucket.datalake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################## S3 Data Lake Lifecycle Configuration (step_01) ##################################

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  provider = aws.target_region

  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.datalake.id

  depends_on = [aws_s3_bucket_versioning.datalake]

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = rule.value.status

      dynamic "filter" {
        for_each = rule.value.filter_prefix != null ? ["this"] : []
        content {
          prefix = rule.value.filter_prefix
        }
      }

      dynamic "filter" {
        for_each = rule.value.filter_prefix == null ? ["this"] : []
        content {}
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? ["this"] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}

################################## S3 Data Lake Bucket Policy - Deny Non-SSL (step_02) ##################################

resource "aws_s3_bucket_policy" "datalake_deny_non_ssl" {
  provider = aws.target_region

  count = var.enforce_ssl ? 1 : 0

  bucket = aws_s3_bucket.datalake.id
  policy = data.aws_iam_policy_document.deny_non_ssl.json
}

################################## IAM Policies (step_03, step_04) ##################################

resource "aws_iam_policy" "role_policy" {
  provider = aws.target_region

  for_each = var.iam_roles

  name        = "${var.name_prefix}-${each.value.policy_suffix}"
  description = each.value.policy_description
  path        = "/"
  policy      = data.aws_iam_policy_document.role_policy[each.key].json

  tags = local.tags
}

################################## IAM Roles (step_05, step_06) ##################################

resource "aws_iam_role" "this" {
  provider = aws.target_region

  for_each = var.iam_roles

  name               = "${var.name_prefix}-${each.value.role_suffix}"
  description        = each.value.description
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = local.tags
}

################################## IAM Role Policy Attachments (step_07, step_08) ##################################

resource "aws_iam_role_policy_attachment" "this" {
  provider = aws.target_region

  for_each = var.iam_roles

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.role_policy[each.key].arn
}

################################## CloudTrail Logging S3 Bucket (step_09) ##################################

resource "aws_s3_bucket" "cloudtrail" {
  provider = aws.target_region

  count = var.cloudtrail_config != null ? 1 : 0

  bucket        = var.cloudtrail_config.log_bucket_name
  force_destroy = var.force_destroy

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  provider = aws.target_region

  count = var.cloudtrail_config != null ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  provider = aws.target_region

  count = var.cloudtrail_config != null ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  provider = aws.target_region

  count = var.cloudtrail_config != null ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################## CloudTrail Logging Bucket Policy (step_10) ##################################

resource "aws_s3_bucket_policy" "cloudtrail" {
  provider = aws.target_region

  count = var.cloudtrail_config != null ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy[0].json
}

################################## CloudTrail Trail (step_11) ##################################

resource "aws_cloudtrail" "this" {
  provider = aws.target_region

  count = var.cloudtrail_config != null ? 1 : 0

  name                          = "${var.name_prefix}-${var.cloudtrail_config.trail_suffix}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  is_multi_region_trail         = try(var.cloudtrail_config.is_multi_region_trail, false)
  enable_logging                = var.cloudtrail_config.enabled
  enable_log_file_validation    = try(var.cloudtrail_config.enable_log_file_validation, true)
  include_global_service_events = false
  kms_key_id                    = local.kms_key_arn

  event_selector {
    read_write_type           = try(var.cloudtrail_config.event_read_write_type, "All")
    include_management_events = try(var.cloudtrail_config.include_management_events, false)

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.datalake.arn}/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = local.tags
}
