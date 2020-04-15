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

resource "aws_key_pair" "auth" {
  key_name = "demo-terraform"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
   

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = var.aws_amis.var.aws_region

  # The name of our SSH keypair we created above.
  key_name = demo-terraform

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.default.id]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = aws_subnet.default.id

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }
}