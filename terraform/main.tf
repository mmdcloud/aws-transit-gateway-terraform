# ----------------------------------------------------------------------
# VPC Configuration
# ----------------------------------------------------------------------
module "vpc1" {
  source                  = "./modules/vpc"
  vpc_name                = "vpc1"
  vpc_cidr                = "10.1.0.0/16"
  azs                     = var.azs
  public_subnets          = var.vpc1_public_subnets
  private_subnets         = var.vpc1_private_subnets
  intra_subnets           = var.vpc1_tgw_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false
  tags = {
    Name = "vpc1"
  }
}

# Security Group
module "vpc1_sg" {
  source = "./modules/security-groups"
  vpc_id = module.vpc1.vpc_id
  name   = "vpc1-sg"
  ingress_rules = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "HTTP from spoke subnets"
    },
    {
      from_port       = -1
      to_port         = -1
      protocol        = "icmp"
      self            = "false"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "ICMP ping from spoke subnets"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "vpc2" {
  source                  = "./modules/vpc"
  vpc_name                = "vpc2"
  vpc_cidr                = "10.2.0.0/16"
  azs                     = var.azs
  public_subnets          = var.vpc2_public_subnets
  private_subnets         = var.vpc2_private_subnets
  intra_subnets           = var.vpc2_tgw_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false
  tags = {
    Name = "vpc2"
  }
}

# Security Group
module "vpc2_sg" {
  source = "./modules/security-groups"
  vpc_id = module.vpc2.vpc_id
  name   = "vpc2-sg"
  ingress_rules = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "HTTP from spoke subnets"
    },
    {
      from_port       = -1
      to_port         = -1
      protocol        = "icmp"
      self            = "false"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "ICMP ping from spoke subnets"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "vpc3" {
  source                  = "./modules/vpc"
  vpc_name                = "vpc3"
  vpc_cidr                = "10.3.0.0/16"
  azs                     = var.azs
  public_subnets          = var.vpc3_public_subnets
  private_subnets         = var.vpc3_private_subnets
  intra_subnets           = var.vpc3_tgw_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false
  tags = {
    Name = "vpc3"
  }
}

# Security Group
module "vpc3_sg" {
  source = "./modules/security-groups"
  vpc_id = module.vpc3.vpc_id
  name   = "vpc3-sg"
  ingress_rules = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "HTTP from spoke subnets"
    },
    {
      from_port       = -1
      to_port         = -1
      protocol        = "icmp"
      self            = "false"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "ICMP ping from spoke subnets"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "SSH access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ----------------------------------------------------------------------
# Centralized Egress VPC (Multi-AZ NAT Gateways)
# ----------------------------------------------------------------------
module "egress_vpc" {
  source                  = "./modules/vpc"
  vpc_name                = "egress-vpc"
  vpc_cidr                = "10.100.0.0/16"
  azs                     = var.azs
  public_subnets          = var.egress_public_subnets
  private_subnets         = var.egress_tgw_subnets # Dedicated /28 subnets for TGW attachment
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true

  # Multi-AZ High Availability NAT Gateways (1 per AZ)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = {
    Name        = "egress-vpc"
    Environment = "Core-Network"
  }
}

# ----------------------------------------------------------------------
# Centralized Inspection VPC (Suricata NVA IDS/IPS)
# ----------------------------------------------------------------------
module "inspection_vpc" {
  source                 = "./modules/vpc"
  vpc_name               = "inspection-vpc"
  vpc_cidr               = "10.200.0.0/16"
  azs                    = var.azs
  private_subnets        = var.inspection_appliance_subnets
  intra_subnets          = var.inspection_tgw_subnets
  enable_dns_hostnames   = true
  enable_dns_support     = true
  create_igw             = false
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  tags = {
    Name        = "inspection-vpc"
    Environment = "Security-Core"
  }
}

# Security Group for Suricata NVA Appliance (Permit transparent packet forwarding & inspection)
module "nva_sg" {
  source = "./modules/security-groups"
  vpc_id = module.inspection_vpc.vpc_id
  name   = "nva-appliance-sg"
  ingress_rules = [
    {
      description     = "Allow all routed traffic for Suricata deep packet inspection"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound forwarded traffic from NVA"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name        = "nva-appliance-sg"
    Environment = "Security-Core"
  }
}

# Suricata Open-Source Network Virtual Appliance (NVA) EC2 Instance Module
module "nva" {
  source                      = "./modules/ec2"
  name                        = "suricata-nva"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.nva_instance_type
  associate_public_ip_address = false
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = module.inspection_vpc.private_subnets[0]
  security_groups             = [module.nva_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data_base64            = filebase64("${path.module}/scripts/nva_user_data.sh")
  source_dest_check           = false

  tags = {
    Role        = "Network-Virtual-Appliance"
    Environment = "Security-Core"
  }
}

# ----------------------------------------------------------------------
# Transit Gateway Configuration
# ----------------------------------------------------------------------
data "aws_caller_identity" "current" {}

module "transit_gateway" {
  source          = "./modules/transit-gateway"
  name            = "transit-gateway"
  description     = "Transit Gateway with Centralized NAT and Suricata NVA Inspection"
  amazon_side_asn = var.primary_tgw_asn

  # Dedicated /28 Subnets for Spoke Attachments
  spoke_attachments = [
    {
      vpc_id     = module.vpc1.vpc_id
      subnet_ids = module.vpc1.intra_subnets
      name       = "vpc1-attachment"
    },
    {
      vpc_id     = module.vpc2.vpc_id
      subnet_ids = module.vpc2.intra_subnets
      name       = "vpc2-attachment"
    },
    {
      vpc_id     = module.vpc3.vpc_id
      subnet_ids = module.vpc3.intra_subnets
      name       = "vpc3-attachment"
    }
  ]

  # Egress VPC Attachment (Appliance Mode Enabled)
  egress_attachment = {
    vpc_id     = module.egress_vpc.vpc_id
    subnet_ids = module.egress_vpc.private_subnets
    name       = "egress-attachment"
  }

  # Central Inspection VPC Attachment (Appliance Mode Enabled)
  inspection_attachment = {
    vpc_id     = module.inspection_vpc.vpc_id
    subnet_ids = module.inspection_vpc.intra_subnets
    name       = "inspection-attachment"
  }
}

# ----------------------------------------------------------------------
# Peer Region Infrastructure & Inter-Region TGW Peering
# ----------------------------------------------------------------------
module "peer_vpc" {
  source                  = "./modules/vpc"
  providers               = { aws = aws.peer }
  vpc_name                = "vpc4-peer"
  vpc_cidr                = var.peer_vpc_cidr
  azs                     = var.peer_azs
  public_subnets          = var.peer_vpc_public_subnets
  private_subnets         = var.peer_vpc_private_subnets
  intra_subnets           = var.peer_vpc_tgw_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false
  tags = {
    Name        = "vpc4-peer"
    Environment = "DR-Peer-Region"
  }
}

module "peer_vpc_sg" {
  source    = "./modules/security-groups"
  providers = { aws = aws.peer }
  vpc_id    = module.peer_vpc.vpc_id
  name      = "vpc4-peer-sg"
  ingress_rules = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "HTTP from primary and peer spoke subnets"
    },
    {
      from_port       = -1
      to_port         = -1
      protocol        = "icmp"
      cidr_blocks     = ["10.0.0.0/8"]
      security_groups = []
      description     = "ICMP ping from primary and peer spoke subnets"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

module "transit_gateway_peering" {
  source = "./modules/transit-gateway-peering"
  providers = {
    aws      = aws
    aws.peer = aws.peer
  }

  name                                   = "tgw"
  primary_transit_gateway_id             = module.transit_gateway.transit_gateway_id
  primary_post_inspection_route_table_id = module.transit_gateway.post_inspection_route_table_id
  primary_inspection_attachment_id       = module.transit_gateway.inspection_attachment_id
  primary_spoke_cidrs                    = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  primary_blackhole_cidrs                = ["10.100.0.0/16", "10.200.0.0/16"]

  peer_region     = var.peer_region
  peer_account_id = data.aws_caller_identity.current.account_id
  peer_tgw_asn    = var.peer_tgw_asn
  peer_spoke_attachments = [
    {
      vpc_id     = module.peer_vpc.vpc_id
      subnet_ids = module.peer_vpc.intra_subnets
      name       = "vpc4-peer-attachment"
    }
  ]
  peer_vpc_cidrs          = [var.peer_vpc_cidr]
  peer_centralized_egress = var.peer_centralized_egress
}

# ----------------------------------------------------------------------
# Inspection VPC Routing
# ----------------------------------------------------------------------

# Route packets entering Inspection VPC via TGW intra subnets to the Suricata NVA ENI
resource "aws_route" "inspection_tgw_to_nva_default" {
  route_table_id         = module.inspection_vpc.intra_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nva.primary_network_interface_id
}

resource "aws_route" "inspection_tgw_to_nva_rfc1918" {
  route_table_id         = module.inspection_vpc.intra_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = module.nva.primary_network_interface_id
}

# Route packets forwarded by Suricata NVA back into Transit Gateway
resource "aws_route" "inspection_nva_to_tgw_default" {
  count                  = length(var.inspection_appliance_subnets)
  route_table_id         = module.inspection_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "inspection_nva_to_tgw_rfc1918" {
  count                  = length(var.inspection_appliance_subnets)
  route_table_id         = module.inspection_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

# ----------------------------------------------------------------------
# Spoke & Egress VPC Routes
# ----------------------------------------------------------------------

# Default route 0.0.0.0/0 from Spoke Private Subnets to Transit Gateway
resource "aws_route" "vpc1_private_default" {
  count                  = length(var.vpc1_private_subnets)
  route_table_id         = module.vpc1.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc2_private_default" {
  count                  = length(var.vpc2_private_subnets)
  route_table_id         = module.vpc2.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc3_private_default" {
  count                  = length(var.vpc3_private_subnets)
  route_table_id         = module.vpc3.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

# Inter-VPC routes for Spoke Public Subnets
resource "aws_route" "vpc1_to_vpc2" {
  route_table_id         = module.vpc1.public_route_table_ids[0]
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc1_to_vpc3" {
  route_table_id         = module.vpc1.public_route_table_ids[0]
  destination_cidr_block = "10.3.0.0/16"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc2_to_vpc1" {
  route_table_id         = module.vpc2.public_route_table_ids[0]
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc2_to_vpc3" {
  route_table_id         = module.vpc2.public_route_table_ids[0]
  destination_cidr_block = "10.3.0.0/16"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc3_to_vpc1" {
  route_table_id         = module.vpc3.public_route_table_ids[0]
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

resource "aws_route" "vpc3_to_vpc2" {
  route_table_id         = module.vpc3.public_route_table_ids[0]
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

# Cross-Region Inter-VPC routes from Primary Spoke Public Subnets to Peer Region VPC
resource "aws_route" "vpc1_to_peer_vpc" {
  route_table_id         = module.vpc1.public_route_table_ids[0]
  destination_cidr_block = var.peer_vpc_cidr
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

resource "aws_route" "vpc2_to_peer_vpc" {
  route_table_id         = module.vpc2.public_route_table_ids[0]
  destination_cidr_block = var.peer_vpc_cidr
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

resource "aws_route" "vpc3_to_peer_vpc" {
  route_table_id         = module.vpc3.public_route_table_ids[0]
  destination_cidr_block = var.peer_vpc_cidr
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

# ----------------------------------------------------------------------
# Peer Region VPC Routes
# ----------------------------------------------------------------------
resource "aws_route" "peer_vpc_private_default" {
  provider               = aws.peer
  count                  = length(var.peer_vpc_private_subnets)
  route_table_id         = module.peer_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway_peering.peer_transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

resource "aws_route" "peer_vpc_to_vpc1" {
  provider               = aws.peer
  route_table_id         = module.peer_vpc.public_route_table_ids[0]
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = module.transit_gateway_peering.peer_transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

resource "aws_route" "peer_vpc_to_vpc2" {
  provider               = aws.peer
  route_table_id         = module.peer_vpc.public_route_table_ids[0]
  destination_cidr_block = "10.2.0.0/16"
  transit_gateway_id     = module.transit_gateway_peering.peer_transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

resource "aws_route" "peer_vpc_to_vpc3" {
  provider               = aws.peer
  route_table_id         = module.peer_vpc.public_route_table_ids[0]
  destination_cidr_block = "10.3.0.0/16"
  transit_gateway_id     = module.transit_gateway_peering.peer_transit_gateway_id
  depends_on             = [module.transit_gateway_peering]
}

# Return route in Egress VPC Public Subnet to route spoke traffic back into Transit Gateway
resource "aws_route" "egress_public_return_to_tgw" {
  route_table_id         = module.egress_vpc.public_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
  depends_on             = [module.transit_gateway]
}

# ----------------------------------------------------------------------
# Test Instances
# ----------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_ami" "ubuntu_peer" {
  provider    = aws.peer
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_key_pair" "key_pair" {
  key_name = "mohitd"
}

# ----------------------------------------------------------------------
# IAM Role & Instance Profile for AWS Systems Manager (SSM)
# ----------------------------------------------------------------------
resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

module "instance1" {
  source                      = "./modules/ec2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = module.vpc1.private_subnets[0]
  security_groups             = [module.vpc1_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")
  name                        = "instance1"
}

module "instance2" {
  source                      = "./modules/ec2"
  name                        = "instance2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = module.vpc2.private_subnets[0]
  security_groups             = [module.vpc2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")
}

module "instance3" {
  source                      = "./modules/ec2"
  name                        = "instance3"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = module.vpc3.private_subnets[0]
  security_groups             = [module.vpc3_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")
}

module "peer_instance" {
  source                      = "./modules/ec2"
  providers                   = { aws = aws.peer }
  name                        = "instance4-peer"
  ami                         = data.aws_ami.ubuntu_peer.id
  instance_type               = "t3.micro"
  associate_public_ip_address = false
  subnet_id                   = module.peer_vpc.private_subnets[0]
  security_groups             = [module.peer_vpc_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data_base64            = filebase64("${path.module}/scripts/user_data.sh")

  tags = {
    Region      = var.peer_region
    Environment = "DR-Peer-Region"
  }

  depends_on = [
    module.nva,
    module.transit_gateway_peering,
    aws_route.peer_vpc_private_default,
    aws_route.inspection_tgw_to_nva_default,
    aws_route.inspection_nva_to_tgw_default,
    aws_route.egress_public_return_to_tgw
  ]
}

# ----------------------------------------------------------------------
# Point 4: AWS RAM Sharing for Multi-Account Deployment
# ----------------------------------------------------------------------
# resource "aws_ram_resource_share" "tgw_share" {
#   name                      = "central-tgw-share"
#   allow_external_principals = false

#   tags = {
#     Name        = "central-tgw-share"
#     Environment = "Production"
#   }
# }

# resource "aws_ram_resource_association" "tgw_assoc" {
#   resource_arn       = module.transit_gateway.transit_gateway_arn
#   resource_share_arn = aws_ram_resource_share.tgw_share.arn
# }

# resource "aws_ram_principal_association" "tgw_principals" {
#   count              = length(var.ram_principals)
#   principal          = var.ram_principals[count.index]
#   resource_share_arn = aws_ram_resource_share.tgw_share.arn
# }