variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ecs_cluster_name" {
  description = "The name of the Amazon ECS cluster."
  default = "jenkins"
}

variable "image_id" {
  description = "Amazon ECS-Optimized AMI."
  type        = string
}

variable "instance_type" {
  description = "The instance type to use."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  default = null
  description = "SSH key name in your AWS account for AWS instances."
}

variable "desired_capacity" {
  default     = 2
}

variable "min_size" {
  default     = 2
  description = "Minimum asg instance count when descaling"
}

variable "max_size" {
  default     = 10
  description = "Maximum asg instance count when upscaling"
}

variable "sg_ids" {
  default     = []
  type        = list(string)
  description = "Additional Security groups"
}