variable "region" {
  description = "The AWS region to create resources in."
  default = "eu-central-1"
}

variable "cluster_name" {
  description = "ECS cluster name"
  default     = "petclinic-CI-QA-deploy"
}