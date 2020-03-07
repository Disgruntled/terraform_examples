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


#module "eks_iam" {
#  source = "./EKS_IAM"
#}

module "instance_profile_build" {
  source = "./SSM_IAM"
}

module "network" {
  source = "./EKS_NETWORK"
  SSMInstanceProfile = module.instance_profile_build.InstanceProfileName
}




module "eks_cluster" {
source = "./EKS_CLUSTER"
vpc_id = module.network.vpc_id
subnet_id = module.network.private_subnet_id
subnet_id2 = module.network.private_subnet_id2
#cluster_role = module.eks_iam.EKSClusterRoleARN
}


output "clustersg" {
  value = module.eks_cluster.clustersg
}



