variable "access_key" {
  description = "The AWS access key."
}

variable "secret_key" {
  description = "The AWS secret key."
}

variable "region" {
  description = "The AWS region to create resources in."
  default = "eu-central-1"
}

variable "ecs_cluster_name" {
  description = "The name of the Amazon ECS cluster."
  default = "jenkins"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  default = "devops-tf"
  description = "SSH key name in your AWS account for AWS instances."
}