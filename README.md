Important information for infosec-devapps-eks

Update the S3 bucket permissions to applow for uploading and managing of state file

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::mybucket"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::mybucket/path/to/my/key"
    }
  ]
}


$ Terraform init

# Import the VPC
$ terraform import aws_vpc.infosecprodeksvpc vpc-082ba2a8a8b3d663c 

# Import the subnet in us-east-2a
$ terraform import aws_subnet.useast2aekssubnet subnet-0ffb42f852fdd12dd

# Import the subnet in us-east-2b
$ terraform import aws_subnet.useast2bekssubnet subnet-0c2e24f442ca2b29d

Terraform plan 
Terraform apply

To destroy without the three resources,

# list all resources
terraform state list

# remove that resource you don't want to destroy
# you can add more to be excluded if required
terraform state rm <resource_to_be_deleted> (aws_subnet.useast2aekssubnet, aws_subnet.useast2bekssubnet, aws_vpc.infosecprodeksvpc)

# destroy the whole stack except above excluded resource(s)
terraform destroy 











Documentation (Draft)

Terraform Notes for creating splunk cluster

Pre-requisites

Ensure that Terraform is installed locally on your PC
Ensure that awscli is installed on your PC
Ensure that the awscli is configured with the access ID and secret key of the user who has adequate permissions to create cluster and roles
In the case that there are existing resources already created in the account, this can be imported using terraform Import


Creating the Providers
Create a main.tf file and populate with the following lines
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

The “required providers” sets us the AWS terraform provider and ensures that a version greater than 3.0 is used.
The provider “aws” allows for specific account properties to be passed in. In this case, the region as well as a profile configured with credentials in awscli is added. 
locals is used to set known values which can be called later in the configuration. Here, the vpc id is stored.


Importing existing resources.
In the specific case here, two subnets have been created in a specific VPC in the account. To import this and have it managed by terraform, the following commands are called following a “terraform plan”

Create a file vpc.tf and add the following lines 
resource "aws_subnet" "useast2aekssubnet" {
    vpc_id                  = local.vpc_id
    cidr_block              = ""
}
$ terraform import aws_subnet.useast2aekssubnet <subnet id>

This pulls in the subnet data and adds it to the generated terraform.tfstate file. The same procedure can be followed for the other subnets.
After this, any required attribute updates can be added such as availability zone, map_public_ip_on_launch and tags. The subnet is now managed by terraform and can be created and destroyed by terraform going forward. The local.vpc_id is used to enforce the known VPC ID to ensure that the right subnet is being imported.

In addition to the sebnets, the aws security group is created to allow access between the control plane and the worker node groups.

resource "aws_security_group" "ekssecuritygroup"{
    description = "Communication between the control plane and worker nodegroups"
    vpc_id = local.vpc_id
     egress = [
        {
        cidr_blocks = [
                  "0.0.0.0/0"
                ],
        from_port = 0,
        description = "",
        protocol = "-1",
        to_port = 0
        ipv6_cidr_blocks = [],
        prefix_list_ids = [],
        security_groups = [],
        self = false,
              }
     ]

tags = {
              "Name"= "infosec-devapps-cluster/ControlPlaneSecurityGroup",
              "terraform/cluster-name"= "infosec-devapps",
              "terraform/cluster-oidc-enabled"= "false",
              "terraform/v1alpha1/cluster-name" = "infosec-devapps"
}
}

Cluster
A new iam.tf file is generated to includes both the cluster role and the node roles. 

Cluster role
The cluster role is required to xxxx
it allows the eks cluster to assume roles and …
This includes the default role policy attachments to ensure that …..
Amazon EKS Cluster Policy
Amazon EKS VPC Resource Controller  

resource "aws_iam_role" "clusterrole" {
  name = "infoseceks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.clusterrole.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.clusterrole.name
}


Nodegroup role
The nodegroup role is also required so that
it allows the ec2 instances to assume roles and …
This includes the default role policy attachments to ensure that …..
Amazon EKS Worker Node Policy
Amazon EKS CNI Policy
Amazon EC2 Container Registry ReadOnly

resource "aws_iam_role" "noderole" {
  name = "infoseceks-nodegroup-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.noderole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.noderole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.noderole.name
}

Eks cluster creation
The aws_eks_cluster is used to create the cluster with required attributes as the cluster name, role_arn, vpc_config. The depends_on attribute ensures that all the roles/ resources that are needed to complete the creation is created before the cluster creation is attempted.


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


EKS Nodegroup creation
The aws_eks_node_group resource is used to create the worker groups which are connected to the cluster. The required attributes include cluster name to join, node role arn, node group name, subnet ids, scaling configs, 

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





Outputs

Optionally, you can generate the output after the successful creation of all resources. In this case, the cluster endpoint as well as the certificate authority data are generated. 

output "endpoint" {
  value = aws_eks_cluster.infosec-eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.infosec-eks.certificate_authority[0].data
}


Terraform plan

terraform


Important information for infosec-devapps-eks

Update the S3 bucket permissions to applow for uploading and managing of state file

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::mybucket"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::mybucket/path/to/my/key"
    }
  ]
}


$ Terraform init

# Import the VPC
$ terraform import aws_vpc.infosecprodeksvpc vpc-082ba2a8a8b3d663c 

# Import the subnet in us-east-2a
$ terraform import aws_subnet.useast2aekssubnet subnet-0ffb42f852fdd12dd

# Import the subnet in us-east-2b
$ terraform import aws_subnet.useast2bekssubnet subnet-0c2e24f442ca2b29d

Terraform plan 
Terraform apply

To destroy without the three resources,

# list all resources
terraform state list

# remove that resource you don't want to destroy
# you can add more to be excluded if required
terraform state rm <resource_to_be_deleted> (aws_subnet.useast2aekssubnet, aws_subnet.useast2bekssubnet, aws_vpc.infosecprodeksvpc)

# destroy the whole stack except above excluded resource(s)
terraform destroy 



resource "aws_subnet" "useast2aekssubnet" {
    vpc_id                  = local.vpc_id
    cidr_block              = "10.243.191.0/25"
    availability_zone       = "us-east-2a"
    map_public_ip_on_launch = false
    tags = {
          "Name" = "Infosec-EKS-subnet1"
          "kubernetes.io/cluster/infosec-devapps" = "owned"
          "kubernetes.io/role/internal-elb"  = "1"
    }
}



resource "aws_subnet" "useast2bekssubnet" {
    vpc_id                  = local.vpc_id
    cidr_block              = "10.243.191.128/25"
    availability_zone       = "us-east-2b"
    map_public_ip_on_launch = false

    tags = {
          "Name" = "Infosec-EKS-subnet2"
          "kubernetes.io/cluster/infosec-devapps" = "owned"
          "kubernetes.io/role/internal-elb"  = "1"
}
}