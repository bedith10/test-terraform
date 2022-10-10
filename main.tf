

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.aws_vpc_cidr_block
  enable_dns_hostnames = var.aws_enable_dns_hostnames
  tags                 = var.aws_vpc_tags
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = var.aws_internet_gateway_tags
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.aws_subnets_cidr_block[0]
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = var.aws_subnet_tags

}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.aws_subnets_cidr_block[1]
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = var.aws_private_subnet_tags

}


####DATA SOURCE###################################
data "aws_availability_zones" "available" {
  state = "available"

}

###################################################


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.aws_route_table_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = var.aws_route_table_tags
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.aws_route_table_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = var.private_route_table_tags
}




resource "aws_route_table_association" "route_public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id

}

resource "aws_route_table_association" "route_private_subnet" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id

}

# sevurity group # Nginx security group
resource "aws_security_group" "sg_nginx1" {
  name   = var.aws_security_group_name
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.aws_security_group_ingress_cidr_block[0]]
  }
  #outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.aws_security_group_egress_cidr_block[0]]
  }
  tags = var.aws_security_group_tags

}

# sevurity group # Nginx2 security group
resource "aws_security_group" "sg_nginx2" {
  name   = var.aws_sg_nginx2_name
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] #[var.main_vpc_cidr_block]
  }
  #outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.aws_security_group_egress_cidr_block
  }
  tags = var.aws_sg_nginx2_tags

}




resource "aws_instance" "public_ec2" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_nginx1.id]
  user_data              = <<EOF
  #! /bin/bash
  sudo amazon-linux-extras install -y nginx1
  sudo service nginx start
  sudo rm /usr/share/nginx/html/index.thml
  echo '<html><head><title>Taco Team Server</title><body style=\"background-color:#1F778D\">
  EOF 

  tags = var.aws_instance_tags
}


resource "aws_instance" "private_ec2" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_instance_type
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_nginx2.id]
  user_data              = <<EOF
  #! /bin/bash
  sudo amazon-linux-extras install -y nginx1
  sudo service nginx start
  sudo rm /usr/share/nginx/html/index.thml
  echo '<html><head><title>Taco Team Server</title><body style=\"background-color:#1F778D\">
  EOF 

  tags = var.aws_private_instance_tags
}





//resource "aws-instance" "web-server" 

