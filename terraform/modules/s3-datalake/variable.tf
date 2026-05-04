################################## General ##################################

variable "name_prefix" {
  description = "Prefix used for naming all resources in this module."
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with core tags from SSM."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encryption. Defaults to account KMS key."
  type        = string
  default     = null
}

################################## S3 Data Lake Bucket ##################################

variable "bucket_name" {
  description = "Name of the primary S3 data lake bucket. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase, and follow S3 naming rules."
  }
}

variable "force_destroy" {
  description = "Whether to allow force-destroying the S3 buckets even if they contain objects."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether versioning is enabled on the data lake bucket."
  type        = bool
  default     = true
}

################################## Lifecycle Configuration ##################################

variable "lifecycle_rules" {
  description = "Map of lifecycle rules for the data lake bucket."
  type = map(object({
    status = optional(string, "Enabled")
    filter_prefix = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.lifecycle_rules :
      contains(["Enabled", "Disabled"], v.status)
    ])
    error_message = "lifecycle_rules status must be 'Enabled' or 'Disabled'."
  }
}

################################## IAM Roles ##################################

variable "iam_roles" {
  description = "Map of IAM roles to create. Key is the role identifier, value contains role configuration."
  type = map(object({
    role_suffix            = string
    description            = optional(string, "")
    trust_principal_arns   = list(string)
    policy_suffix          = string
    policy_description     = optional(string, "")
    policy_statements = list(object({
      sid       = optional(string)
      effect    = optional(string, "Allow")
      actions   = list(string)
      resources = list(string)
    }))
  }))
  default = {}
}

################################## CloudTrail ##################################

variable "cloudtrail_config" {
  description = "Configuration for CloudTrail trail monitoring the data lake bucket."
  type = object({
    enabled                     = bool
    trail_suffix                = string
    log_bucket_name             = string
    is_multi_region_trail       = optional(bool, false)
    enable_log_file_validation  = optional(bool, true)
    include_management_events   = optional(bool, false)
    event_read_write_type       = optional(string, "All")
  })
  default = null

  validation {
    condition     = var.cloudtrail_config == null ? true : contains(["All", "ReadOnly", "WriteOnly"], var.cloudtrail_config.event_read_write_type)
    error_message = "event_read_write_type must be 'All', 'ReadOnly', or 'WriteOnly'."
  }
}

################################## Bucket Policy ##################################

variable "enforce_ssl" {
  description = "Whether to attach a bucket policy denying non-HTTPS requests to the data lake bucket."
  type        = bool
  default     = true
}
