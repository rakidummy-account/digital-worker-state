################################## VPC ##################################

resource "aws_vpc" "this" {
  provider = aws.target_region

  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.tags, {
    Name = var.name_prefix
  })
}

################################## Internet Gateway ##################################

resource "aws_internet_gateway" "this" {
  provider = aws.target_region

  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

################################## Public Subnets ##################################

resource "aws_subnet" "public" {
  provider = aws.target_region

  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-public-${each.key}"
  })
}

################################## Private Subnets ##################################

resource "aws_subnet" "private" {
  provider = aws.target_region

  for_each = var.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-private-${each.key}"
  })
}

################################## Public Route Table ##################################

resource "aws_route_table" "public" {
  provider = aws.target_region

  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  provider = aws.target_region

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  provider = aws.target_region

  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

################################## Elastic IPs for NAT Gateways ##################################

resource "aws_eip" "nat" {
  provider = aws.target_region

  for_each = var.nat_gateways

  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-nat-eip-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

################################## NAT Gateways ##################################

resource "aws_nat_gateway" "this" {
  provider = aws.target_region

  for_each = var.nat_gateways

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value.public_subnet_key].id

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-nat-gw-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

################################## Private Route Tables ##################################

resource "aws_route_table" "private" {
  provider = aws.target_region

  for_each = var.private_route_tables

  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-private-rt-${each.key}"
  })
}

resource "aws_route" "private_nat" {
  provider = aws.target_region

  for_each = var.private_route_tables

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value.nat_gateway_key].id
}

resource "aws_route_table_association" "private" {
  provider = aws.target_region

  for_each = var.private_route_tables

  subnet_id      = aws_subnet.private[each.value.private_subnet_key].id
  route_table_id = aws_route_table.private[each.key].id
}

################################## Security Groups ##################################

resource "aws_security_group" "this" {
  provider = aws.target_region

  for_each = var.security_groups

  name        = "${var.name_prefix}-${each.key}"
  description = each.value.description
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = try(ingress.value.description, null)
    }
  }

  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = try(egress.value.description, null)
    }
  }

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}

################################## CloudWatch Log Group for Flow Logs ##################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  provider = aws.target_region

  count = var.flow_log_config != null ? 1 : 0

  name              = "/${var.name_prefix}/vpc-flow-logs"
  retention_in_days = var.flow_log_config.retention_in_days
  kms_key_id        = local.kms_key_arn

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}

################################## IAM Role for Flow Logs ##################################

resource "aws_iam_role" "flow_logs" {
  provider = aws.target_region

  count = var.flow_log_config != null ? 1 : 0

  name = "${var.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-flow-logs-role"
  })
}

################################## IAM Role Policy for Flow Logs ##################################

resource "aws_iam_role_policy" "flow_logs" {
  provider = aws.target_region

  count = var.flow_log_config != null ? 1 : 0

  name = "${var.name_prefix}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

################################## VPC Flow Log ##################################

resource "aws_flow_log" "this" {
  provider = aws.target_region

  count = var.flow_log_config != null ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = var.flow_log_config.traffic_type
  log_destination_type = var.flow_log_config.log_destination_type
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-flow-log"
  })
}
