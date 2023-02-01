terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "~> 3.0"
   }
 }
}
 
provider "aws" {
 region = "us-east-2"
 profile = "abbviesplunkk8s"
}
locals {
  vpc_id = "vpc-082ba2a8a8b3d663c"
}

resource "aws_eks_cluster" "infosec-eks" {
  name     = "infosec-devapps"
  role_arn = aws_iam_role.clusterrole.arn
  version = "1.24"
  enabled_cluster_log_types = ["controllerManager",]
  vpc_config {
   subnet_ids = [aws_subnet.useast2aekssubnet.id, aws_subnet.useast2bekssubnet.id]
   endpoint_private_access   = true
   endpoint_public_access    = false
   security_group_ids        = [aws_security_group.ekssecuritygroup.id,]
 }
  tags = {
   "Name" = "infosec-devapps-cluster/ControlPlane"
   "terraform/cluster-name" = "infosec-devapps"
   "terraform/cluster-oidc-enabled" = "false"
   "terraform/v1alpha1/cluster-name" = "infosec-devapps"
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_security_group.ekssecuritygroup,
  ]
}



resource "aws_eks_node_group" "infosecdevnode" {
  node_role_arn = aws_iam_role.noderole.arn
  cluster_name = "infosec-devapps"
  node_group_name = "infosecnodes"
  subnet_ids = [aws_subnet.useast2aekssubnet.id, aws_subnet.useast2bekssubnet.id]
  
instance_types = ["m4.2xlarge"]
scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.infosec-eks,
  ]
  }

output "endpoint" {
  value = aws_eks_cluster.infosec-eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.infosec-eks.certificate_authority[0].data
}