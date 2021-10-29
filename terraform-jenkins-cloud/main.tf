provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

resource "aws_key_pair" this {
  key_name   = "ci-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCg57JG/eU8U2phRUTD/Hdh4DFhjn7GnlODfdwkL0EqbcTt3ygw/h27bn1/wxouLAXGRMbbHeaGjorARTA9V3ekz/Sr5WORHN+6zMKH7+oI6nqqJ5/EwPur1wN5xltbFc8aV+btS9Qn9lDcS5zXSavqabkI2G9MYBAZR0+6vZj4/1i79de7CMDhVW0Ic9VWTmit7ddwPQthrCZvl7OE2aHeDjI4cSGhf6qE7O5yMmfYIKKxjlmvMNuItvGzHTd4aXhe7ylYUVkEKotO+Kde5Wjr4wr685a2XUATJQLeWeJ/IzTThjruDQGWXfaWblONBVqjJ9v1r/fi6uh+o22uWqOxwsIVyRkP7u9uJR3CibW5d9nLo/yPKspmgHIzfQEozosndZeiBIscqGT7EVNViH6cVfzho4wJGXjYVDjwj5m0BsfPH0003FqnckZOjkztSQRawjnjcIk9OBiY7gEgVZtkGye2nN/fsZbdZBMpNi09S6kEzdJ7IE7K8A6nM14P0Gs= placid@dell-pc"
}


# subnets public cos nat is required for private  subnets
module "asg_for_ecs" {
  source            = "./modules/asg_for_ecs"
  vpc_id            = aws_vpc.jenkins.id
  subnet_ids        = aws_subnet.public[*].id
  ecs_cluster_name  = var.ecs_cluster_name
  instance_type     = "t3.micro"
  desired_capacity  = 2
  min_size          = 1
  max_size          = 10
  key_name          = aws_key_pair.this.key_name
  sg_ids            = [aws_security_group.jenkins.id]
}

resource "aws_ecs_capacity_provider" "this" {
  name = "asg_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg_for_ecs.asg_arn
    managed_termination_protection = "ENABLED"
    
    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
    }
  }
}

resource "aws_ecs_cluster" "jenkins" {
  name = var.ecs_cluster_name
  capacity_providers = [aws_ecs_capacity_provider.this.name, "FARGATE_SPOT", "FARGATE"]
  
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
  }
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Terraform = "true"
  }
}

module "jenkins_cloud" {
  source              = "./modules/jenkins_cloud"

  vpc_id              = aws_vpc.jenkins.id
  private_subnet_ids  = aws_subnet.private[*].id
  public_subnet_ids   = aws_subnet.public[*].id
  ecs_cluster_id      = aws_ecs_cluster.jenkins.id
}

resource "aws_security_group" "jenkins" {
  name        = "sg_jenkins_instance"
  description = "for cluster of jenkins master and agents"
  vpc_id      = aws_vpc.jenkins.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 50000
    to_port   = 50000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol= "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform = "true"
  }
}
