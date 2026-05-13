# Get Jenkins public IP from the module
output "jenkins_public_ip" {
  value = module.jenkins.jenkins_public_ip
}

# Also output the private key path (or we can assume it's known)
output "jenkins_ssh_key_name" {
  value = var.ssh_key_name   # we'll add this variable
}