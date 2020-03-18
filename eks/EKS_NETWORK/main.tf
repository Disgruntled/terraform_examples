provider "aws" {
  profile = var.profile
  region  = var.region
}


#Grab the latest AL2 AMI to use in our nat instances.
#Works in any region.
data "aws_ami" "al2_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


#Get the latest list of AZs in our region.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.13.37.0/24"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  #EKS uses tags on VPC/Subnets for discovery.
  #The tag key should be a variable and allow the user to specify the cluster name. TODO: add that functionality.
  tags = {
    Name = "tf_VPC"
    "kubernetes.io/cluster/${var.clustername}" = "shared"
  }
}

resource "aws_subnet" "tf_priv_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.0/27"
  availability_zone = data.aws_availability_zones.available.names[0]

  #Subnets used by kubernetes must be tagged as such, with a tag that references the name of your cluster
  #Creating the EKS cluster does this, but these have been set in the infra such that later modifications don't over write the tag values. This is teh value "shared"
  #private subnets used by your EKS cluster need "kubernetes.io/role/internal-elb = 1"
  tags = {
    Name = "tf_priv_subnet"
    "kubernetes.io/cluster/${var.clustername}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"

  }
}

resource "aws_subnet" "tf_priv_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.32/27"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "tf_priv_subnet2"
    "kubernetes.io/cluster/${var.clustername}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"


  }
}

resource "aws_subnet" "tf_public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.64/27"
  availability_zone = data.aws_availability_zones.available.names[0]

  #Public subnets (where you want public ELBs), need the tag "kubernetes.io/role/elb" = "1"
  tags = {
    Name = "tf_public_subnet"
    "kubernetes.io/cluster/${var.clustername}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}
resource "aws_subnet" "tf_public_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.96/27"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "tf_public_subnet2"
    "kubernetes.io/cluster/${var.clustername}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform_igw"
  }
}

resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.NatInstance.id
  }

  tags = {
    Name = "private_subnet_route_table"
  }
}

resource "aws_route_table" "tf_private_route_table2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.NatInstance2.id
  }

  tags = {
    Name = "private_subnet_route_table2"
  }
}

resource "aws_route_table" "tf_public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = "public_subnet_route_table"
  }
}

resource "aws_route_table_association" "tf_public_route_association" {
  subnet_id      = aws_subnet.tf_public_subnet.id
  route_table_id = aws_route_table.tf_public_route_table.id
}

resource "aws_route_table_association" "tf_public_route_association2" {
  subnet_id      = aws_subnet.tf_public_subnet2.id
  route_table_id = aws_route_table.tf_public_route_table.id
}

resource "aws_route_table_association" "tf_private_route_association" {
  subnet_id      = aws_subnet.tf_priv_subnet.id
  route_table_id = aws_route_table.tf_private_route_table.id
}

resource "aws_route_table_association" "tf_private_route_association2" {
  subnet_id      = aws_subnet.tf_priv_subnet2.id
  route_table_id = aws_route_table.tf_private_route_table2.id
}

resource "aws_security_group" "nat_instance_sg" {
  name        = "nat_instance_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "NatInstanceSG"
  }
}


#Done correctly, you can SSM:SM into this instance
resource "aws_instance" "NatInstance" {
  ami                         = data.aws_ami.al2_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_public_subnet.id
  associate_public_ip_address = "true"
  source_dest_check           = "false"
  vpc_security_group_ids      = [aws_security_group.nat_instance_sg.id]
  iam_instance_profile        = var.SSMInstanceProfile
  user_data                   = <<EOF
#!/bin/bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo service sshd stop
sudo systemctl stop rpcbind
  EOF

  tags = {
    Name = "NatInstance"
  }
}

resource "aws_instance" "NatInstance2" {
  ami                         = data.aws_ami.al2_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_public_subnet2.id
  associate_public_ip_address = "true"
  source_dest_check           = "false"
  vpc_security_group_ids      = [aws_security_group.nat_instance_sg.id]
  iam_instance_profile        = var.SSMInstanceProfile
  user_data                   = <<EOF
#!/bin/bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo service sshd stop
sudo systemctl stop rpcbind
  EOF

  tags = {
    Name = "NatInstance2"
  }
}