vpc1_public_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
vpc1_private_subnets = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
vpc2_public_subnets  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
vpc2_private_subnets = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
vpc3_public_subnets  = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
vpc3_private_subnets = ["10.3.4.0/24", "10.3.5.0/24", "10.3.6.0/24"]
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
region               = "us-east-1"

# Point 1: Dedicated /28 TGW Subnets
vpc1_tgw_subnets = ["10.1.254.0/28", "10.1.254.16/28", "10.1.254.32/28"]
vpc2_tgw_subnets = ["10.2.254.0/28", "10.2.254.16/28", "10.2.254.32/28"]
vpc3_tgw_subnets = ["10.3.254.0/28", "10.3.254.16/28", "10.3.254.32/28"]

# Point 2: Egress Subnets for Multi-AZ NAT Gateways & TGW
egress_public_subnets = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
egress_tgw_subnets    = ["10.100.254.0/28", "10.100.254.16/28", "10.100.254.32/28"]

# Central Inspection VPC & Suricata NVA Appliance
inspection_appliance_subnets = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
inspection_tgw_subnets       = ["10.200.254.0/28", "10.200.254.16/28", "10.200.254.32/28"]
nva_instance_type            = "t3.small"

# Inter-Region Transit Gateway Peering (Secondary Region)
peer_region              = "us-west-2"
peer_azs                 = ["us-west-2a", "us-west-2b", "us-west-2c"]
primary_tgw_asn          = 64512
peer_tgw_asn             = 64513
peer_vpc_cidr            = "10.4.0.0/16"
peer_vpc_public_subnets  = ["10.4.1.0/24", "10.4.2.0/24", "10.4.3.0/24"]
peer_vpc_private_subnets = ["10.4.4.0/24", "10.4.5.0/24", "10.4.6.0/24"]
peer_vpc_tgw_subnets     = ["10.4.254.0/28", "10.4.254.16/28", "10.4.254.32/28"]
peer_centralized_egress  = true

# Point 4: RAM Principals (Leave empty until sharing across AWS Accounts/Org)
ram_principals = []
