################################## VPC ##################################

output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = module.vpc.vpc.cidr_block
}

################################## Subnets ##################################

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = { for k, v in module.vpc.public_subnets : k => v.id }
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = { for k, v in module.vpc.private_subnets : k => v.id }
}

################################## Internet Gateway ##################################

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = module.vpc.internet_gateway.id
}

################################## NAT Gateways ##################################

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways."
  value       = { for k, v in module.vpc.nat_gateways : k => v.id }
}

################################## Security Groups ##################################

output "security_group_ids" {
  description = "IDs of security groups."
  value       = { for k, v in module.vpc.security_groups : k => v.id }
}

################################## Flow Logs ##################################

output "flow_log_ids" {
  description = "IDs of VPC Flow Logs."
  value       = [for fl in module.vpc.flow_log : fl.id]
}
