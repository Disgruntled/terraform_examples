provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_iam_role" "EKSClusterRole" {
  name = "EKSClusterRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#Default required IAM policies
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.EKSClusterRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.EKSClusterRole.name
}

resource "aws_security_group" "ClusterSG" {
  name        = "ClusterG"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ClusterSG"
  }
}


resource "aws_eks_cluster" "EKSClusterTF" {
  name            = "EKSClusterTF"
  role_arn        = aws_iam_role.EKSClusterRole.arn


#Required to allow the EKS cluster to nuke it's security group when you terraform destroy.
    depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
  ]

  vpc_config {
    subnet_ids         = [var.subnet_id, var.subnet_id2]
    endpoint_public_access = true 
    security_group_ids = [aws_security_group.ClusterSG.id]
  }
}
