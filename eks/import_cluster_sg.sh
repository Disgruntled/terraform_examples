#!/bin/bash

#Imports the terraform cluster SG, as this resource is made orphaned by the AWS provider. It must be imported to be destroyed
#Very hacky. Manipulates TF file. Would need some weird modules to figure this out.

export EKS_CLUSTER_SG=$(terraform output clustersg)

mv sg_import.ft sg_import.tf

terraform import aws_security_group.ClusterMasterSg $EKS_CLUSTER_SG

mv sg_import.tf sg_import.ft

