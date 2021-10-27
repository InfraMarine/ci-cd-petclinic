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

module "ecs_cluster" {
  source = "infrablocks/ecs-cluster/aws"
  
  region = var.region
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  security_groups = [aws_security_group.app_instance.id]

  component = "petclinic"
  deployment_identifier = "CI-QA"
  
  cluster_name = "deploy"
  cluster_instance_ssh_public_key_path = "../.ssh/deploy_rsa.pub"
  cluster_instance_type = "t3.micro"
  associate_public_ip_addresses = "yes"
  cluster_minimum_size = 0
  cluster_maximum_size = 4
  cluster_desired_capacity = 0
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