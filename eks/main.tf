provider "aws" {
  profile = var.profile
  region  = var.region
}


module "instance_profile_build" {
  source = "./SSM_IAM"
}

module "network" {
  source = "./EKS_NETWORK"
  SSMInstanceProfile = module.instance_profile_build.InstanceProfileName
  clustername = var.clustername
}




module "eks_cluster" {
source = "./EKS_CLUSTER"
vpc_id = module.network.vpc_id
subnet_id = module.network.private_subnet_id
subnet_id2 = module.network.private_subnet_id2
clustername = var.clustername

}

module "eks_workers" {
source = "./EKS_WORKERS"
vpc_id = module.network.vpc_id
cluster_sg = module.eks_cluster.ClusterSG
cluster_endpoint = module.eks_cluster.ClusterEndPoint
cluster_ca = module.eks_cluster.ClusterCA
cluster_version = module.eks_cluster.ClusterVersion
cluster_subnet_1 = module.network.private_subnet_id
cluster_subnet_2 = module.network.private_subnet_id2
clustername = var.clustername

}



locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${module.eks_workers.WorkerNodeRole}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

}


