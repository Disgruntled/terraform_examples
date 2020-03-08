output "ClusterSG" {
  value = aws_security_group.ClusterSG.id
}

output "ClusterEndPoint" {
  value = aws_eks_cluster.EKSClusterTF.endpoint
}

output "ClusterCA" {
  value = aws_eks_cluster.EKSClusterTF.certificate_authority[0].data
}

output "ClusterVersion" {
  value = aws_eks_cluster.EKSClusterTF.version
}


