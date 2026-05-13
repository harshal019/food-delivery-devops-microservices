variable "env" {}
variable "cluster_name" {}
variable "cluster_version" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "cluster_sg_ids" { type = list(string) }
variable "cluster_role_arn" {}
variable "nodegroup_role_arn" {}
variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = string
  }))
}
variable "addons" { type = map(string) }