variable "aws_region" {
  default = "us-east-2"
}

variable "env" {
  description = "Environment name (dev/staging/prod)"
}

variable "project_name" {
  default = "foodapp"
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "eks"
}

variable "jenkins_instance_type" {
  default = "t3.large"
}

variable "jenkins_volume_size" {
  default = 30
}

variable "ssh_public_key_path" {
  default = "~/.ssh/jenkins-key.pub"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair used for Jenkins (without .pem)"
  default     = "jenkins-key"
}
variable "eks_instance_types" {
  default = ["t3.medium"]
}

variable "eks_desired_size" {
  default = 3
}

variable "eks_min_size" {
  default = 2
}

variable "eks_max_size" {
  default = 5
}

variable "ami_id" {
  default = "ami-0fe18bc3cfa53a248"
}