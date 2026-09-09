module "aws_load_balancer_controller" {
  source  = "dasmeta/eks/aws//modules/aws-load-balancer-controller"
  version = "2.29.1"

  cluster_name = var.cluster_name
  region       = var.region

  vpc_id = var.vpc_id

  iam = {
    attachment_method = "service_account_role_annotation"
  }
}