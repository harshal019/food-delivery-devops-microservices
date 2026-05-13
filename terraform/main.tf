# ==============================================
# MODULE 1: VPC (Network)



# ==============================================
module "vpc" {
  source = "./modules/vpc"

  env          = var.env
  project_name         = var.project_name
  cluster_name         = var.cluster_name
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"] # Fixed syntax
}

# ==============================================
# MODULE 2: IAM (Roles & Instance Profiles)
# ==============================================
module "iam" {
  source = "./modules/iam"

  env  = var.env
  project_name = var.project_name
  cluster_name = var.cluster_name
}

# ==============================================
# MODULE 3: EKS (Kubernetes Cluster)
# ============================================== ==============================================
# MODULE 3: EKS (Kubernetes Cluster)
# ==============================================
module "eks" {
  source = "./modules/eks"

  env          = var.env
  cluster_name         = var.cluster_name
  cluster_version      = "1.31"              # Changed to 1.31
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  cluster_sg_ids       = [module.vpc.eks_cluster_sg_id]
  cluster_role_arn     = module.iam.eks_cluster_role_arn
  nodegroup_role_arn   = module.iam.eks_nodegroup_role_arn

  node_groups = {
    main = {
      instance_types = var.eks_instance_types
      desired_size   = var.eks_desired_size
      min_size       = var.eks_min_size
      max_size       = var.eks_max_size
      capacity_type  = "ON_DEMAND"
    }
  }

 # Addons compatible with Kubernetes 1.31 (AWS default versions)
  addons = {
    coredns    = null    # AWS will use default compatible version
    kube-proxy = null    # AWS will use default compatible version
    vpc-cni    = null    # AWS will use default compatible version
  }
}

# ==============================================
# MODULE 4: Jenkins Server (Public) - Hardcoded Ubuntu AMI
# ==============================================
module "jenkins" {
  source = "./modules/jenkins-ec2"

  env               = var.env
  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  jenkins_security_group_id = module.vpc.jenkins_sg_id
  jenkins_instance_profile  = module.iam.jenkins_instance_profile_name

  instance_type       = var.jenkins_instance_type
  volume_size         = var.jenkins_volume_size
  ssh_public_key_path = var.ssh_public_key_path


  ami_id = var.ami_id

}