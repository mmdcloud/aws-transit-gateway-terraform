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
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
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
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
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
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
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
# Transit Gateway Configuration
# ----------------------------------------------------------------------
module "transit_gateway" {
  source      = "./modules/transit-gateway"
  name        = "transit-gateway"
  description = "Transit Gateway for VPCs"
  attachments = [
    {
      vpc_id     = module.vpc1.vpc_id
      subnet_ids = module.vpc1.public_subnets
    },
    {
      vpc_id     = module.vpc2.vpc_id
      subnet_ids = module.vpc2.public_subnets
    },
    {
      vpc_id     = module.vpc3.vpc_id
      subnet_ids = module.vpc3.public_subnets
    }
  ]
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
  key_name = "madmaxkeypair"
}

module "instance1" {
  source                      = "./modules/ec2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name        = data.aws_key_pair.key_pair.key_name
  subnet_id       = module.vpc1.public_subnets[0]
  security_groups = [module.vpc1_sg.id]
  user_data       = filebase64("${path.module}/scripts/user_data.sh")
  name            = "instance1"
}

module "instance2" {
  source                      = "./modules/ec2"
  name                        = "instance2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name        = data.aws_key_pair.key_pair.key_name
  subnet_id       = module.vpc2.public_subnets[0]
  security_groups = [module.vpc2_sg.id]
  user_data       = filebase64("${path.module}/scripts/user_data.sh")
}

module "instance3" {
  source                      = "./modules/ec2"
  name                        = "instance3"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = module.vpc3.public_subnets[0]
  security_groups             = [module.vpc3_sg.id]
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")
}
