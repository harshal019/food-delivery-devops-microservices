output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_certificate_authority" { value = aws_eks_cluster.main.certificate_authority[0].data }