provider "aws" {
  profile = var.profile
  region  = var.region
}

########
########Create the environment for worker nodes, their security groups, and their role/instance profile.
########
########

resource "aws_iam_role" "EKSWorkerNodeRole" {
  name = "terraform-eks-demo-node"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.EKSWorkerNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.EKSWorkerNodeRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.EKSWorkerNodeRole.name
}

resource "aws_iam_role_policy_attachment" "SSMforEKSNode" {
  role = aws_iam_role.EKSWorkerNodeRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "EKSWorkerNodeProfile" {
  name = "EKSWorkerNodeProfile"
  role = aws_iam_role.EKSWorkerNodeRole.name
}


resource "aws_security_group" "EKSNodeSG" {
  name        = "EKSNodeSG"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = "Eks Node Security Group"
    "kubernetes.io/cluster/EKSClusterTF" = "owned"
  }
}

resource "aws_security_group_rule" "node-ingress-self-rule" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.EKSNodeSG.id
  source_security_group_id = aws_security_group.EKSNodeSG.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster-rule" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control      plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.EKSNodeSG.id
  source_security_group_id = var.cluster_sg
  to_port                  = 65535
  type                     = "ingress"
 }

 resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = var.cluster_sg
  source_security_group_id = aws_security_group.EKSNodeSG.id
  to_port                  = 443
  type                     = "ingress"
}

########
########Create the Auto Scaling group for our eks workers.
########
########

data "aws_ami" "eks-worker" {
   filter {
     name   = "name"
     values = ["amazon-eks-node-${var.cluster_version}-v*"]
   }

   most_recent = true
   owners      = ["602401143452"] # Amazon EKS AMI Account ID
 }


locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${var.cluster_endpoint}' --b64-cluster-ca '${var.cluster_ca}' EKSClusterTF
USERDATA

}

resource "aws_launch_configuration" "EksCluster" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.EKSWorkerNodeProfile.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "m4.large"
  name_prefix                 = "EKSCluster"
  security_groups  = [aws_security_group.EKSNodeSG.id]
  user_data_base64 = base64encode(local.demo-node-userdata)
  associate_public_ip_address = False

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "EKSNodes" {
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.EksCluster.id
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks"
  vpc_zone_identifier = [var.cluster_subnet_1, var.cluster_subnet_2]

  tag {
    key                 = "Name"
    value               = "terraform-eks"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/EKSClusterTF"
    value               = "owned"
    propagate_at_launch = true
  }
}
