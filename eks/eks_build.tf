
module "eks_iam" {
  source = "./EKS_IAM"
}

module "instance_profile_build" {
  source = "./SSM_IAM"
}

module "network" {
  source = "./EKS_NETWORK"
  SSMInstanceProfile = module.instance_profile_build.InstanceProfileName
}

output "nat_instance_id" {
  value = module.network.nat_instance_id
}


#module "eks_cluster" {
#source = "./EKS_CLUSTER"
#vpc_id = module.network.vpc_id
#subnet_id = module.network.private_subnet_id
#cluster_role = EKSClusterRoleARN
#}
