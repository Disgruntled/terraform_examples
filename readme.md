# Some Terraform Examples

In this repository I'm keeping a few terraform examples that I made during my first attempts to learn the tool. My initial goal was to be able to spin up an environment with outbound internet connectivity that I could use for testing an anytime, and explore some of the features of terraform.

## Requirements

terraform version 0.12 syntax is used, so please make sure you're at <= terraform 0.12

## Invocation

Both templates take two variables, the REGION and PROFILE

```
terraform plan -out liam.plan -var="region=us-east-2" -var="profile=saml"
```

Region should be the AWS region you want to deploy to, formatted the official manner, EG: "us-east-1" or "us-west-2". Should work fine withe very region. Defaults to us-east-1.

profile should be the profile within .aws/credentials that terraform will use to execute. Normally this is default, but if you've done a little customization you can override the default. Defaults to "default"

Due note that it is necesarry to include variables in terraform destroy later as well.

## vpc_with_nat_gw.tf

This will create a two subnet-vpc with a nat GW, and the public/private routing setup.

It will also create a iam role/instance profile for use with SSM, so you can use SSM-Session Manager to connect into it, which is easy if you're lazy.

## vpc_with_nat_instance.tf

This will create a two subnet-vpc with a nat instance, and the public/private routing setup.

It will also create a iam role/instance profile for use with SSM, so you can use SSM-Session Manager to connect into it, which is easy if you're lazy.

Nat instances can be way cheaper than Nat gateways, and as this instance is t2.micro, it is both free tier eligible and much cheaper than a nat gateway

## EKS

So this is somethign a bit neat, this will create a multi AZ deployment of the VPC with nat instance above, but will also deploy an EKS cluster into that, and takes care of creating the service linked roles for you. As part of the expansion of my learning journey, this was done with terraform modules and it was actually really hand.

the EKS deployment takes on extra, optional variable "clustername". Defaults to "EKSClusterTF" if none is specified.

Sample Invocation:

```
terraform plan -out liam.plan -var="region=us-east-2" -var="profile=saml" -var="clustername=foocluster"
```


SSM_IAM creates the instance profile/roles to use SSM on your nat instances, and your cluser nodes should you want. Also very handy for using them as a remote workstation.

EKS_NETWORK builds out the network as described above

EKS_CLUSTER builds out the EKS cluster in the two private subnets as part of your network. 

EKS_WORKERS spins up two nodes and configures them to join your cluster.

### EKS Nodes

The EKS_WORKERS module creates an autoscaling group in your to host your kubernetes nodes. This will be spun up, but you have to manually tell kubectl to let them join the cluster. The auto scaling group is currently using the default EKS optimized AMI, but my plan is to later roll my own AMI that has SSM agent installed.

With some instructions stolen right from the official terraform guide on EKS, you may do the following after your terraform apply is complete to configure your kubernetes cluster to allow your nodes to join.

Essentially, we're telling eks to allow hosts with that IAM Role/Instance profile to be allowed to join the cluster.

```
terraform output config_map_aws_auth and save the configuration into a file, e.g. config_map_aws_auth.yaml
kubectl apply -f config_map_aws_auth.yaml
```

### Kubectl config

To update your kubectl to work with EKS, you may simply run:

```
aws eks update-kubeconfig --name [YourClusterNameHere]
```

With the cluster name of your choice

### Helm

There's a simple helm chart to install deployment of my simple container 'forever200' via helm.

To deploy the container to the cluster and have it accesible via ELB, you can navigate to the eks/helm directory and run:

```
helm install forever200 ./forever200
```

The helm chart is basically the default one you get from 'helm create', with the slightest of modifications to start my container and use it with a 'loadbalancer'
