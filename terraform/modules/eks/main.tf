resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false # PRIVATE CLUSTER
    security_group_ids      = var.cluster_sg_ids
  }

  tags = { Name = var.cluster_name, Env = var.env }
}

# OIDC Provider (required for service accounts)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Node Groups (ONLY ON-DEMAND)
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = var.nodegroup_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type # "ON_DEMAND"

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  tags       = { Name = "${var.cluster_name}-${each.key}-nodes" }
  depends_on = [aws_eks_cluster.main]
}

# Add-ons
# EKS Add-ons
resource "aws_eks_addon" "addons" {
  for_each = var.addons

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = each.key
  addon_version = each.value
  resolve_conflicts_on_update = "OVERWRITE"   # Add this to handle version updates

  depends_on = [aws_eks_node_group.main]
}

