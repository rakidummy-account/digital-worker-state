################################## VPC Module ##################################
## Payments service production VPC with public/private subnets, NAT GWs, flow logs

module "vpc" {
  source = "../../"
  providers = {
    aws.primary = aws.primary
  }

  #required
  name_prefix  = "payments-prod"
  vpc_cidr_block = "10.10.0.0/16"

  #optional
  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnets = {
    "1a" = {
      cidr_block              = "10.10.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
    }
    "1b" = {
      cidr_block              = "10.10.2.0/24"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = true
    }
  }

  private_subnets = {
    "1a" = {
      cidr_block              = "10.10.10.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
    }
    "1b" = {
      cidr_block              = "10.10.20.0/24"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = false
    }
  }

  nat_gateways = {
    "1a" = {
      public_subnet_key = "1a"
    }
    "1b" = {
      public_subnet_key = "1b"
    }
  }

  private_route_tables = {
    "1a" = {
      nat_gateway_key    = "1a"
      private_subnet_key = "1a"
    }
    "1b" = {
      nat_gateway_key    = "1b"
      private_subnet_key = "1b"
    }
  }

  security_groups = {
    "public-sg" = {
      description = "Public SG - HTTPS inbound from anywhere"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow HTTPS inbound"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }
    "private-sg" = {
      description = "Private SG - deny all inbound, allow all outbound"
      ingress_rules = []
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }
  }

  flow_log_config = {
    traffic_type         = "ALL"
    retention_in_days    = 90
    log_destination_type = "cloud-watch-logs"
  }

  tags = { ManagedBy = "terraform" }
}
