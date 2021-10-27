variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_cluster_id" {
}

#from https://github.com/aws-samples/serverless-jenkins-on-aws-fargate

variable efs_access_point_uid {
  type        = number
  description = "The uid number to associate with the EFS access point" // Jenkins 1000
  default     = 1000
}

variable efs_access_point_gid {
  type        = number
  description = "The gid number to associate with the EFS access point" // Jenkins 1000
  default     = 1000
}