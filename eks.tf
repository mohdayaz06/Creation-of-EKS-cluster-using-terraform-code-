module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name    = local.name
  cluster_version = "1.34"

  cluster_endpoint_public_access = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # ✅ ONLY cluster SG has the kubernetes tag
  cluster_security_group_tags = {
    "kubernetes.io/cluster/${local.name}" = "owned"
  }

  # ✅ Explicitly remove it from node SG
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.name}" = null
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.small"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    cluster-wg = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      capacity_type = "SPOT"

      labels = {
        role = "worker"
        env  = "dev"
      }
    }
  }

  tags = local.tags
}
