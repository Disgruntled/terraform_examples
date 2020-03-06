provider "aws" {
  profile = var.profile
  region  = var.region
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
  role_arn        = var.cluster_role

  vpc_config {
    subnet_ids         = [var.subnet_id, var.subnet_id2]
    endpoint_public_access = true 
    security_group_ids = [aws_security_group.ClusterSG.id]
  }
}
