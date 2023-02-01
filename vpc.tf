# resource "aws_vpc" "infosecprodeksvpc" {
#     cidr_block           = "10.243.191.0/24"
#     enable_dns_hostnames = true
#     enable_dns_support   = true
#     instance_tenancy     = "default"

#     tags = {
#               "Account_id"= "979580570505",
#               "AppSupportQueue"= "ISS-Global-Hadoop CORE",
#               "Automation"= "yes",
#               "BusinessOwner"= "Eugene Rinaldi",
#               "CompanyCode"="6003",
#               "Cost Center"= "600201",
#               "Creator"= "PATCHBX",
#               "Environment"= "PROD",
#               "Name"= "Infosec Prod EKS VPC",
#               "Region"= "us-east-2"

# }
# }

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
