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

module "egress_vpc" {
  source                  = "./modules/vpc"
  vpc_name                = "egress-vpc"
  vpc_cidr                = "10.100.0.0/16"
  azs                     = var.azs
  public_subnets          = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  private_subnets         = ["10.100.4.0/24", "10.100.5.0/24", "10.100.6.0/24"] # Used for TGW attachments
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true # Set to false and one_nat_gateway_per_az = true for Multi-AZ HA
  one_nat_gateway_per_az  = false
  tags = {
    Name = "egress-vpc"
  }
}

# ----------------------------------------------------------------------
# Transit Gateway Configuration
# ----------------------------------------------------------------------
module "transit_gateway" {
  source      = "./modules/transit-gateway"
  name        = "transit-gateway"
  description = "Transit Gateway with Centralized NAT"

  spoke_attachments = [
    {
      vpc_id     = module.vpc1.vpc_id
      subnet_ids = module.vpc1.private_subnets
      name       = "vpc1-attachment"
    },
    {
      vpc_id     = module.vpc2.vpc_id
      subnet_ids = module.vpc2.private_subnets
      name       = "vpc2-attachment"
    },
    {
      vpc_id     = module.vpc3.vpc_id
      subnet_ids = module.vpc3.private_subnets
      name       = "vpc3-attachment"
    }
  ]

  egress_attachment = {
    vpc_id     = module.egress_vpc.vpc_id
    subnet_ids = module.egress_vpc.private_subnets
    name       = "egress-attachment"
  }
}

# ----------------------------------------------------------------------
# Route Table Routes
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
  #availability_zone           = var.azs[0].id
  key_name             = data.aws_key_pair.key_pair.key_name
  subnet_id            = module.vpc1.private_subnets[0]
  security_groups      = [module.vpc1_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  user_data            = filebase64("${path.module}/scripts/user_data.sh")
  name                 = "instance1"
}

module "instance2" {
  source                      = "./modules/ec2"
  name                        = "instance2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  #availability_zone           = var.azs[0].id
  key_name             = data.aws_key_pair.key_pair.key_name
  subnet_id            = module.vpc2.private_subnets[0]
  security_groups      = [module.vpc2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  user_data            = filebase64("${path.module}/scripts/user_data.sh")
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