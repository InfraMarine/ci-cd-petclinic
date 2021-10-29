provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_ecr_repository" this {
  name                 = "spring-petclinic"
  image_tag_mutability = "MUTABLE"
}

resource "aws_key_pair" this {
  key_name   = "deploy-key"
  public_key = file("../.ssh/deploy_rsa.pub")
}

# subnets public cos nat is required for private  subnets
module "asg_for_ecs" {
  source            = "../terraform-jenkins-cloud/modules/asg_for_ecs" # publish this module?
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnets
  ecs_cluster_name  = var.cluster_name
  instance_type     = "t3.micro"
  desired_capacity  = 1
  min_size          = 0
  max_size          = 3
  key_name          = aws_key_pair.this.key_name
  sg_ids            = [aws_security_group.app_instance.id]
}

resource "aws_ecs_capacity_provider" "this" {
  name = "deploy_asg_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg_for_ecs.asg_arn
    
    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.this.name]
  
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 100
  }

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Terraform = "true"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "deploy-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
  }
}

resource "aws_security_group" "app_instance" {
  name        = "spring-app-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Terraform = "true"
  }
}