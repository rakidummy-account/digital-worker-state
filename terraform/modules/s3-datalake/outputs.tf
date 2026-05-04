################################## S3 Data Lake Bucket ##################################

output "datalake_bucket" {
  description = "All attributes of the S3 data lake bucket."
  value       = aws_s3_bucket.datalake
}

output "datalake_versioning" {
  description = "All attributes of the S3 data lake bucket versioning configuration."
  value       = aws_s3_bucket_versioning.datalake
}

output "datalake_encryption" {
  description = "All attributes of the S3 data lake bucket server-side encryption configuration."
  value       = aws_s3_bucket_server_side_encryption_configuration.datalake
}

output "datalake_public_access_block" {
  description = "All attributes of the S3 data lake bucket public access block."
  value       = aws_s3_bucket_public_access_block.datalake
}

output "datalake_lifecycle" {
  description = "All attributes of the S3 data lake bucket lifecycle configuration."
  value       = aws_s3_bucket_lifecycle_configuration.datalake
}

################################## Bucket Policies ##################################

output "datalake_bucket_policy" {
  description = "All attributes of the S3 data lake deny-non-SSL bucket policy."
  value       = aws_s3_bucket_policy.datalake_deny_non_ssl
}

################################## IAM ##################################

output "iam_roles" {
  description = "All attributes of the IAM roles, keyed by role identifier."
  value       = aws_iam_role.this
}

output "iam_policies" {
  description = "All attributes of the IAM policies, keyed by role identifier."
  value       = aws_iam_policy.role_policy
}

output "iam_role_policy_attachments" {
  description = "All attributes of the IAM role policy attachments, keyed by role identifier."
  value       = aws_iam_role_policy_attachment.this
}

################################## CloudTrail ##################################

output "cloudtrail_bucket" {
  description = "All attributes of the CloudTrail logging S3 bucket."
  value       = aws_s3_bucket.cloudtrail
}

output "cloudtrail_trail" {
  description = "All attributes of the CloudTrail trail."
  value       = aws_cloudtrail.this
}
