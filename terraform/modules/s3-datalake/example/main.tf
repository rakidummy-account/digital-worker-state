################################## S3 Data Lake Module ##################################
## Provision S3 Data Lake with IAM Access Controls, Encryption, Lifecycle, CloudTrail, and Bucket Policy

module "s3_datalake" {
  source = "../../"
  providers = {
    aws.primary = aws.primary
  }

  # required
  name_prefix = "datalake"
  bucket_name = "company-datalake-prod"

  # optional
  force_destroy      = false
  versioning_enabled = true
  enforce_ssl        = true

  lifecycle_rules = {
    glacier-transition = {
      status = "Enabled"
      transitions = [
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  }

  iam_roles = {
    data_engineers = {
      role_suffix          = "data-engineers-role"
      description          = "IAM role for data engineers with read/write access to the data lake"
      trust_principal_arns = ["arn:aws:iam::${var.account}:root"]
      policy_suffix        = "data-engineers-rw-policy"
      policy_description   = "Read/write access policy for data engineers on the data lake bucket"
      policy_statements = [
        {
          sid    = "AllowObjectReadWrite"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListMultipartUploadParts",
            "s3:AbortMultipartUpload",
          ]
          resources = ["arn:aws:s3:::company-datalake-prod/*"]
        },
        {
          sid    = "AllowBucketList"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetBucketLocation",
          ]
          resources = ["arn:aws:s3:::company-datalake-prod"]
        },
      ]
    }
    data_analysts = {
      role_suffix          = "data-analysts-role"
      description          = "IAM role for data analysts with read-only access to the data lake"
      trust_principal_arns = ["arn:aws:iam::${var.account}:root"]
      policy_suffix        = "data-analysts-ro-policy"
      policy_description   = "Read-only access policy for data analysts on the data lake bucket"
      policy_statements = [
        {
          sid    = "AllowObjectRead"
          effect = "Allow"
          actions = [
            "s3:GetObject",
          ]
          resources = ["arn:aws:s3:::company-datalake-prod/*"]
        },
        {
          sid    = "AllowBucketList"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetBucketLocation",
          ]
          resources = ["arn:aws:s3:::company-datalake-prod"]
        },
      ]
    }
  }

  cloudtrail_config = {
    enabled                    = true
    trail_suffix               = "prod-trail"
    log_bucket_name            = "company-datalake-prod-cloudtrail-logs"
    is_multi_region_trail      = false
    enable_log_file_validation = true
    include_management_events  = false
    event_read_write_type      = "All"
  }

  tags = { ManagedBy = "terraform" }
}
