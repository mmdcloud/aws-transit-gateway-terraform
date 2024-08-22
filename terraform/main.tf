# VPC1
resource "aws_vpc" "vpc1" {
  cidr_block = "10.1.0.0/24"
  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "vpc1_subnets" {
  count             = length(var.vpc1_subnets)
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = element(var.vpc1_subnets, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "vpc1_subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "vpc1_igw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "vpc1_igw"
  }
}

resource "aws_route_table" "vpc1_route_table" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1_igw.id
  }
  route {
    cidr_block         = "10.2.0.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  }
  route {
    cidr_block         = "10.3.0.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  }
  tags = {
    Name = "vpc1_route_table"
  }
}

resource "aws_route_table_association" "vpc1_route_table_association" {
  count          = length(var.vpc1_subnets)
  subnet_id      = element(aws_subnet.vpc1_subnets[*].id, count.index)
  route_table_id = aws_route_table.vpc1_route_table.id
}

# VPC2
resource "aws_vpc" "vpc2" {
  cidr_block = "10.2.0.0/24"
  tags = {
    Name = "vpc2"
  }
}

resource "aws_subnet" "vpc2_subnets" {
  count             = length(var.vpc2_subnets)
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = element(var.vpc2_subnets, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "vpc2_subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "vpc2_igw" {
  vpc_id = aws_vpc.vpc2.id
  tags = {
    Name = "vpc2_igw"
  }
}

resource "aws_route_table" "vpc2_route_table" {
  vpc_id = aws_vpc.vpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc2_igw.id
  }
  route {
    cidr_block         = "10.1.0.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  }
  route {
    cidr_block         = "10.3.0.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  }
  tags = {
    Name = "vpc2_route_table"
  }
}

resource "aws_route_table_association" "vpc2_route_table_association" {
  count          = length(var.vpc2_subnets)
  subnet_id      = element(aws_subnet.vpc2_subnets[*].id, count.index)
  route_table_id = aws_route_table.vpc2_route_table.id
}

# VPC3
resource "aws_vpc" "vpc3" {
  cidr_block = "10.3.0.0/24"
  tags = {
    Name = "vpc3"
  }
}

resource "aws_subnet" "vpc3_subnets" {
  count             = length(var.vpc3_subnets)
  vpc_id            = aws_vpc.vpc3.id
  cidr_block        = element(var.vpc3_subnets, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "vpc3_subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "vpc3_igw" {
  vpc_id = aws_vpc.vpc3.id
  tags = {
    Name = "vpc3_igw"
  }
}

resource "aws_route_table" "vpc3_route_table" {
  vpc_id = aws_vpc.vpc3.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc3_igw.id
  }
  route {
    cidr_block         = "10.1.0.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  }
  route {
    cidr_block         = "10.2.0.0/24"
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  }
  tags = {
    Name = "vpc3_route_table"
  }
}

resource "aws_route_table_association" "vpc3_route_table_association" {
  count          = length(var.vpc3_subnets)
  subnet_id      = element(aws_subnet.vpc3_subnets[*].id, count.index)
  route_table_id = aws_route_table.vpc3_route_table.id
}

# Transit Gateway 
resource "aws_ec2_transit_gateway" "transit_gateway" {
  description = "Transit Gateway"
  tags = {
    Name = "transit-gateway"
  }
}

# Transit Gateway Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_1" {
  subnet_ids         = aws_subnet.vpc1_subnets[*].id
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = aws_vpc.vpc1.id
  depends_on         = [aws_vpc.vpc1]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_2" {
  subnet_ids         = aws_subnet.vpc2_subnets[*].id
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = aws_vpc.vpc2.id
  depends_on         = [aws_vpc.vpc2]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_3" {
  subnet_ids         = aws_subnet.vpc3_subnets[*].id
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = aws_vpc.vpc3.id
  depends_on         = [aws_vpc.vpc3]
}

resource "aws_security_group" "vpc1_sg" {
  name   = "vpc1_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc2_sg" {
  name   = "vpc2_sg"
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc3_sg" {
  name   = "vpc3_sg"
  vpc_id = aws_vpc.vpc3.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
  key_name = "surajm"
}

resource "aws_instance" "instance1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.vpc1_subnets[0].id
  security_groups             = [aws_security_group.vpc1_sg.id]
  user_data                   = "${file("user_data.sh")}"
  tags = {
    Name = "instance1"
  }
}

resource "aws_instance" "instance2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.vpc2_subnets[0].id
  security_groups             = [aws_security_group.vpc2_sg.id]
  user_data                   = "${file("user_data.sh")}"
  tags = {
    Name = "instance2"
  }
}

resource "aws_instance" "instance3" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  #availability_zone           = var.azs[0].id
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.vpc3_subnets[0].id
  security_groups             = [aws_security_group.vpc3_sg.id]
  user_data                   = "${file("user_data.sh")}"
  tags = {
    Name = "instance3"
  }
}
