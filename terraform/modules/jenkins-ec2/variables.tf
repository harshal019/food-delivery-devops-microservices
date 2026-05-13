variable "env" {}
variable "project_name" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "jenkins_security_group_id" {}
variable "jenkins_instance_profile" {}
variable "instance_type" {}
variable "volume_size" {}
variable "ssh_public_key_path" {}
variable "ami_id" {
  description = "Hardcoded Ubuntu AMI ID"
  type        = string
}
