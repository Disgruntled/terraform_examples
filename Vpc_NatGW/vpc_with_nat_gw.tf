####Author: Liam.wadman@gmail.com
####Purpose: Create an easy AWS environment that can reach out to the internet.
####Creates a 2AZ/Subnet VPC deployment and a Nat GW to forward traffic.
####All hosts booted in the tf_priv_subnet will be able to connect to the internet
####Also creates an EC2 instance profile with the SSM policy, so you can SSM-SM connect into the instance

variable "region" {
  type    = string
  default = "us-east-1"

}

variable "profile" {
  type    = string
  default = "default"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}


data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.13.37.0/24"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "tf_VPC"
  }
}

resource "aws_subnet" "tf_priv_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.0/27"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tf_priv_subnet"

  }
}

resource "aws_subnet" "tf_public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.13.37.32/27"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tf_public_subnet"
  }
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform_igw"
  }
}




resource "aws_eip" "terraform_eip" {
  vpc = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.tf_public_subnet.id

  tags = {
    Name = "terraform_nat_gw"
  }
}

resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "private_subnet_route_table"
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

resource "aws_route_table_association" "tf_private_route_association" {
  subnet_id      = aws_subnet.tf_priv_subnet.id
  route_table_id = aws_route_table.tf_private_route_table.id
}


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

output "private_subnet_id" {
  value = aws_subnet.tf_public_subnet.id
}

output "vpc_id" {
  value = aws_vpc.main.id