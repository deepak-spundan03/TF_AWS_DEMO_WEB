# Define our VPC
resource "aws_vpc" "web" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "dedicated"
  
  tags = {
    Name = "web-vpc"
  }
}

# Define the public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.web.id
  cidr_block = var.public_subnet_cidr
  availability_zone = "us-east-1d"
  

  tags = {
    Name = "web-public-subnet"
  }
}

# Define the private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.web.id
  cidr_block = var.private_subnet_cidr
  availability_zone = "us-east-1d"

  tags = {
    Name = "web-private-subnet"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.web.id

  tags = {
    Name = "web-internet-gateway"
  }
}

# Define the nat eip
resource "aws_eip" "nat" {
  vpc      = true

  tags = {
    Name = "web-nat-eip"
  }
}


# Define the nat gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "web-nat-gateway"
  }
}

# Define the public route table
resource "aws_route_table" "web-public-rt" {
  vpc_id = aws_vpc.web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }

  tags = {
    Name = "web-public-rt"
  }
}

# Define the private route table
resource "aws_route_table" "web-private-rt" {
  vpc_id = aws_vpc.web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "web-private-rt"
  }
}



# Assign the route table to the public Subnet
resource "aws_route_table_association" "web-public-rt" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.web-public-rt.id
}

# Assign the route table to the private Subnet
resource "aws_route_table_association" "web-private-rt" {
  subnet_id = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.web-private-rt.id
}

# Define the security group for subnet
resource "aws_security_group" "web-security-group" {
  name = "vpc_test_web"
  description = "Allow incoming HTTP connections & SSH access"
  vpc_id= aws_vpc.web.id

  tags = {
    Name = "web-security-group"
  }
}

# default security group  
resource "aws_security_group_rule" "allow-ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     =  ["182.70.231.76/32"]
  security_group_id = aws_security_group.web-security-group.id


}

resource "aws_security_group_rule" "allow-http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     =  ["182.70.231.76/32"]
  security_group_id = aws_security_group.web-security-group.id

 
}

resource "aws_security_group_rule" "allow-https" {
  count = var.enable_https == "true" ? 1 : 0 
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     =  ["182.70.231.76/32"]
  security_group_id = aws_security_group.web-security-group.id

 
}

resource "aws_security_group_rule" "allow-outbound-http" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     =  ["0.0.0.0/0"]
  security_group_id = aws_security_group.web-security-group.id

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  tags = {
    Name = "hello-nginx"
  }
}

