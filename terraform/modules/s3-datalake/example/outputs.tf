################################## S3 Data Lake Outputs ##################################

output "datalake_bucket_id" {
  description = "ID of the S3 data lake bucket."
  value       = module.s3_datalake.datalake_bucket.id
}

output "datalake_bucket_arn" {
  description = "ARN of the S3 data lake bucket."
  value       = module.s3_datalake.datalake_bucket.arn
}

################################## IAM Outputs ##################################

output "data_engineers_role_arn" {
  description = "ARN of the data engineers IAM role."
  value       = module.s3_datalake.iam_roles["data_engineers"].arn
}

output "data_analysts_role_arn" {
  description = "ARN of the data analysts IAM role."
  value       = module.s3_datalake.iam_roles["data_analysts"].arn
}

output "data_engineers_policy_arn" {
  description = "ARN of the data engineers IAM policy."
  value       = module.s3_datalake.iam_policies["data_engineers"].arn
}

output "data_analysts_policy_arn" {
  description = "ARN of the data analysts IAM policy."
  value       = module.s3_datalake.iam_policies["data_analysts"].arn
}

################################## CloudTrail Outputs ##################################

output "cloudtrail_bucket_id" {
  description = "ID of the CloudTrail logging S3 bucket."
  value       = module.s3_datalake.cloudtrail_bucket[0].id
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = module.s3_datalake.cloudtrail_trail[0].arn
}
