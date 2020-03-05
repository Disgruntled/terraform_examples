provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "EKSClusterSG"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EKSClusterSG"
  }
}

resource "aws_eks_cluster" "EKSClusterTF" {
  name            = "EKSClusterTF"
  role_arn        = cluster_role

  vpc_config {
    security_group_ids = aws_security_group.eks_cluster_sg.id
    subnet_ids         = [subnet_id]
  }
}
