output "eks_cluster_role_arn" { value = aws_iam_role.eks_cluster.arn }
output "eks_nodegroup_role_arn" { value = aws_iam_role.eks_nodegroup.arn }
output "jenkins_instance_profile_name" { value = aws_iam_instance_profile.jenkins.name }