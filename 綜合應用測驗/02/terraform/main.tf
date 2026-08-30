################################################################################
# VPC
################################################################################

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  az_number            = var.az_number <= length(data.aws_availability_zones.available.names) ? var.az_number : length(data.aws_availability_zones.available.names)
  azs                  = slice(data.aws_availability_zones.available.names, 0, local.az_number)
  public_subnet_cidrs  = [for i in range(var.public_subnet_number) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i in range(var.private_subnet_number) : cidrsubnet(var.vpc_cidr, 4, 1 + i)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.2"

  name = "asiayo"
  azs  = local.azs
  cidr = var.vpc_cidr

  public_subnets = local.public_subnet_cidrs
  public_subnet_tags = {
    Tier                     = "public"
    "kubernetes.io/role/elb" = 1
  }
  public_route_table_tags = {
    Tier = "public"
  }
  one_nat_gateway_per_az       = true
  map_public_ip_on_launch      = true
  public_dedicated_network_acl = true

  private_subnets = local.private_subnet_cidrs
  private_subnet_tags = {
    Tier = "private"
  }
  private_route_table_tags = {
    Tier = "private"
  }
  private_dedicated_network_acl = true

  enable_nat_gateway = true

  manage_default_security_group = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
}

################################################################################
# EKS
################################################################################

module "aws_vpc_cni_ipv4_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.9.0"

  name                      = "aws-vpc-cni-ipv4"
  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true
}

module "aws_efs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.9.0"

  name                      = "aws-efs-csi"
  attach_aws_efs_csi_policy = true
}

module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.9.0"

  name                      = "aws-ebs-csi"
  attach_aws_ebs_csi_policy = true
}

module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.9.0"

  name                            = "aws-lbc"
  attach_aws_lb_controller_policy = true

  associations = {
    asiayo = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.0"

  name                                     = "asiayo"
  kubernetes_version                       = "1.36"
  force_update_version                     = false
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  addons = {
    eks-pod-identity-agent = {
      before_compute = true
    }
    vpc-cni = {
      before_compute = true
      pod_identity_association = [
        {
          role_arn        = module.aws_vpc_cni_ipv4_pod_identity.iam_role_arn
          service_account = "aws-node"
        }
      ]
    }
    coredns    = {}
    kube-proxy = {}
    aws-efs-csi-driver = {
      pod_identity_association = [
        {
          role_arn        = module.aws_efs_csi_pod_identity.iam_role_arn
          service_account = "efs-csi-controller-sa"
        }
      ]
    }
    aws-ebs-csi-driver = {
      pod_identity_association = [
        {
          role_arn        = module.aws_ebs_csi_pod_identity.iam_role_arn
          service_account = "ebs-csi-controller-sa"
        }
      ]
    }
  }

  eks_managed_node_groups = {
    default-136 = {
      instance_types = ["m6i.large"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 3
      max_size       = 5
      desired_size   = 3
    }
  }
}

################################################################################
# EFS
################################################################################

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "2.2.1"

  name             = "asiayo"
  performance_mode = "generalPurpose"

  create_backup_policy = false

  security_group_vpc_id          = module.vpc.vpc_id
  security_group_name            = "asiayo-efs"
  security_group_use_name_prefix = true
  security_group_ingress_rules = {
    efs = {
      referenced_security_group_id = module.eks.node_security_group_id
    }
  }

  mount_targets = {
    a = {
      subnet_id = module.vpc.private_subnets[0]
    },
    b = {
      subnet_id = module.vpc.private_subnets[1]
    },
    c = {
      subnet_id = module.vpc.private_subnets[2]
    }
  }
}
