################################## General ##################################

variable "name_prefix" {
  description = "Prefix used for naming all resources in this module."
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with core tags for all resources."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encryption. Defaults to account KMS key."
  type        = string
  default     = null
}

################################## VPC ##################################

variable "vpc_cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid CIDR block."
  }
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC."
  type        = bool
  default     = false
}

################################## Subnets ##################################

variable "public_subnets" {
  description = "Map of public subnets to create. Key is a logical name suffix."
  type = map(object({
    cidr_block               = string
    availability_zone        = string
    map_public_ip_on_launch  = optional(bool, true)
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnets to create. Key is a logical name suffix."
  type = map(object({
    cidr_block               = string
    availability_zone        = string
    map_public_ip_on_launch  = optional(bool, false)
  }))
  default = {}
}

################################## NAT Gateways ##################################

variable "nat_gateways" {
  description = "Map of NAT gateways to create. Key is a logical name suffix. public_subnet_key must reference a key in var.public_subnets."
  type = map(object({
    public_subnet_key = string
  }))
  default = {}
}

################################## Private Route Tables ##################################

variable "private_route_tables" {
  description = "Map of private route tables. Key is logical name suffix. nat_gateway_key references var.nat_gateways, private_subnet_key references var.private_subnets."
  type = map(object({
    nat_gateway_key    = string
    private_subnet_key = string
  }))
  default = {}
}

################################## Security Groups ##################################

variable "security_groups" {
  description = "Map of security groups to create. Key is a logical name suffix."
  type = map(object({
    description = optional(string, "Managed by Terraform")
    ingress_rules = optional(list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = optional(string)
    })), [])
    egress_rules = optional(list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = optional(string)
    })), [])
  }))
  default = {}
}

################################## Flow Logs ##################################

variable "flow_log_config" {
  description = "Configuration for VPC Flow Logs. Set to null to disable."
  type = object({
    traffic_type         = string
    retention_in_days    = number
    log_destination_type = optional(string, "cloud-watch-logs")
  })
  default = null

  validation {
    condition     = var.flow_log_config == null ? true : contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_config.traffic_type)
    error_message = "traffic_type must be ACCEPT, REJECT, or ALL."
  }
}
