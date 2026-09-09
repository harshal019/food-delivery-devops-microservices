output "jenkins_public_ip" {
  value = module.jenkins.jenkins_public_ip
}

output "jenkins_ssh_key_name" {
  value = var.ssh_key_name
}