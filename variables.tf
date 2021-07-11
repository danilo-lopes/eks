variable aws_region {
  description = "AWS Region"
  type        = string
}

/// Tags
variable tags {
  description = "Aditional tags"
  type    = map(string)
  default = {}
}

/// VPC
variable vpc_id {
  description = "ID of VPC"
  type        = string
}

variable private_subnets_id {
  description = "Private Subnets ID"
  type        = list(string)
}

/// EKS
variable cluster_name {
  description = "EKS Cluster Name"
  type        = string
}

variable cluster_version {
  description = "EKS Cluster Version"
  type        = string
}

variable enable_cluster_logs {
  description = "The EKS modules to be logged in CloudWatch Log Group"
  type        = list(string)
  default     = []
}

variable cluster_log_retention_in_days {
  description = "Time to retain cluster logs in cloudwatch"
  type        = number
  default     = 90
}

variable cluster_endpoint_public_access {
  description = "External Access to the Control Plane API"
  type        = bool
  default     = true
}

variable cluster_endpoint_private_access {
  description = "Internal Access to the Control Plane API"
  type        = bool
  default     = true
}

variable node_group_scaling_settings {
  description = "EKS Node Groups Scaling Capacities"
  type        = map
}

variable node_group_shape {
  description = "EKS Node Group Instance Shape"
  type        = string
}

variable aws_profile_name {
  description   = "AWS Profile Name who will provision the cluster"
  type          = map(string)
}

variable node_group_ssh_key_name {
  description = "EC2 SSH Key Name to administrate the worker nodes through ssh"
  type        = string
  default     = null
}

/// ALB
variable deploy_alb_controller {
  description = "Deploy Application Load Balancer Ingress Controller"
  type        = bool
  default     = false
}

variable map_users {
  description = "Additional IAM users to add to the aws-auth configmap"
  type        = list(object({
    userarn   = string
    username  = string
    groups    = list(string)
  }))
  default     = []
}

variable map_roles {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type        = list(object({
    rolearn   = string
    username  = string
    groups    = list(string)
  }))
  default     = []
}