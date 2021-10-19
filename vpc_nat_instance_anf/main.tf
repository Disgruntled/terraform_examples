####Author: liam.wadman@gmail.com
####Purpose: Create an easy AWS environment that can reach out to the internet.
####Creates a 1AZ/VPC deployment and a nat instance to forward traffic, AND amazon network firewall in the path
####Nat Instances can be highly desireable for non-prod environments due to the cost savings.
####All hosts booted in the tf_priv_subnet will be able to connect to the internet
####Also creates an EC2 instance profile with the SSM policy, so you can SSM-SM connect into the instance
resource "aws_vpc" "main" {
  cidr_block           = "10.13.37.0/24"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "tf_VPC"
  }
}

#####################################
#Subnets 
#####################################

#classic private subnet
resource "aws_subnet" "tf_priv_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.0/27"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tf_priv_subnet"

  }
}

#Nat instance subnet
resource "aws_subnet" "tf_public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.32/27"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tf_public_subnet"
  }
}

#subnet which the VPCE for ANF will live in
resource "aws_subnet" "tf_firewall_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.64/27"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tf_firewall_subnet"
  }
}

#####################################
#IGW
#####################################

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform_igw"
  }
}

#####################################
#Route tables
#####################################

#Table for the private subnet"
resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.NatInstance.id
  }

  tags = {
    Name = "tf_private_subnet_route_table"
  }
}

#Table for the public subnet/subnet that 'nats'
resource "aws_route_table" "tf_public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = data.aws_vpc_endpoint.firewall.id
  }

  tags = {
    Name = "tf_public_subnet_route_table"
  }
}

#Routing table associated with the subnet ANF lives in.
resource "aws_route_table" "tf_firewall_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = "tf_firewall_subnet_route_table"
  }
}

#Routing table associated with the IGW
resource "aws_route_table" "tf_edge_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "10.13.37.32/27"
    vpc_endpoint_id = data.aws_vpc_endpoint.firewall.id
  }

  tags = {
    Name = "tf_edge_route_table"
  }
}



#####################################
#Route table associations
#####################################

resource "aws_route_table_association" "tf_public_route_association" {
  subnet_id      = aws_subnet.tf_public_subnet.id
  route_table_id = aws_route_table.tf_public_route_table.id
}

resource "aws_route_table_association" "tf_private_route_association" {
  subnet_id      = aws_subnet.tf_priv_subnet.id
  route_table_id = aws_route_table.tf_private_route_table.id
}

resource "aws_route_table_association" "tf_firewall_route_association" {
  subnet_id      = aws_subnet.tf_firewall_subnet.id
  route_table_id = aws_route_table.tf_firewall_route_table.id
}

resource "aws_route_table_association" "tf_edge_route_association" {
  gateway_id     = aws_internet_gateway.terraform_igw.id
  route_table_id = aws_route_table.tf_edge_route_table.id
}


#because I like using SSM;SM to test, here we have SSM:SM being setup
resource "aws_iam_role" "default_ec2_instance_policy" {
  name = "default_ec2_instance_policy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "Roles_for_default_ec2_instance_policy" {
  name  = "Roles_for_default_ec2_instance_policy"
  roles = [aws_iam_role.default_ec2_instance_policy.name]
  ####Use of the AmazonEC2RoleforSSM policy is not a good practice. 
  ####It includes the entitlement "S3:GetObject" without a resource clause, 
  ####so potentially anyone or attacker with access to this ec2 instance 
  ####may be able to read all your buckets unless you take further steps!!!!!
  ####Real scenarios with an obligation to protect data should make a better policy.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

}

resource "aws_iam_instance_profile" "ssm_instance_profile_tf" {
  name = "ssm_instance_profile_tf"
  role = aws_iam_role.default_ec2_instance_policy.name
}


resource "aws_security_group" "nat_instance_sg" {
  name        = "nat_instance_sg"
  description = "Allow All Traffic into/out of the NAT instance"
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


#Please note that SSM has SSH and rpcbind disabled for additional hardening, but you can hit it via
#AWS SSM session manager
resource "aws_instance" "NatInstance" {
  ami                         = data.aws_ami.al2_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_public_subnet.id
  associate_public_ip_address = "true"
  source_dest_check           = "false"
  vpc_security_group_ids      = [aws_security_group.nat_instance_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile_tf.id
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

#####################################
#Network firewall setup
#####################################

resource "aws_networkfirewall_firewall_policy" "tf_firewall_policy" {
  name = "tffirewallpolicy"
#Firewall will pass all stateless passess to stateful. In most cases, you want this.
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:drop"]
  }
}

resource "aws_networkfirewall_firewall" "tf_anf" {
  name                = "tfanf"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.tf_firewall_policy.arn
  vpc_id              = aws_vpc.main.id
  subnet_mapping {
    subnet_id = aws_subnet.tf_firewall_subnet.id
  }
#reference "endpoint_id" for routing
}

