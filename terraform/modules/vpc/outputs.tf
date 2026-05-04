################################## VPC ##################################

output "vpc" {
  description = "All attributes of the VPC."
  value       = aws_vpc.this.id
}

################################## Internet Gateway ##################################

output "internet_gateway" {
  description = "All attributes of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

################################## Subnets ##################################

output "public_subnets" {
  description = "All attributes of public subnets (map keyed by subnet logical name)."
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnets" {
  description = "All attributes of private subnets (map keyed by subnet logical name)."
  value       = { for k, v in aws_subnet.private : k => v.id }
}

################################## Route Tables ##################################

output "public_route_table" {
  description = "All attributes of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_tables" {
  description = "All attributes of private route tables (map keyed by route table logical name)."
  value       = { for k, v in aws_route_table.private : k => v.id }
}

################################## Elastic IPs ##################################

output "nat_eips" {
  description = "All attributes of NAT Gateway Elastic IPs (map keyed by NAT gateway logical name)."
  value       = { for k, v in aws_eip.nat : k => v.id }
}

################################## NAT Gateways ##################################

output "nat_gateways" {
  description = "All attributes of NAT Gateways (map keyed by NAT gateway logical name)."
  value       = { for k, v in aws_nat_gateway.this : k => v.id }
}

################################## Security Groups ##################################

output "security_groups" {
  description = "All attributes of security groups (map keyed by security group logical name)."
  value       = { for k, v in aws_security_group.this : k => v.id }
}

################################## Flow Logs ##################################

output "cloudwatch_log_group" {
  description = "All attributes of the CloudWatch Log Group for VPC Flow Logs."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].id, null)
}

output "flow_log_iam_role" {
  description = "All attributes of the IAM Role for VPC Flow Logs."
  value       = try(aws_iam_role.flow_logs[0].id, null)
}

output "flow_log" {
  description = "All attributes of the VPC Flow Log."
  value       = try(aws_flow_log.this[0].id, null)
}
