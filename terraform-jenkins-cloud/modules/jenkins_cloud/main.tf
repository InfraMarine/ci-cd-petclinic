data "aws_vpc" this {
  id = var.vpc_id
}

#logging
resource "aws_cloudwatch_log_group" "jenkins" {
  name = "jenkins"
}

resource "aws_ecs_service" "jenkins" {
  name = "jenkins"
  cluster = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.jenkins.arn
  desired_count = 1
  deployment_minimum_healthy_percent  = 100
  health_check_grace_period_seconds   = 45
  launch_type                         = "EC2"

  # network_configuration {
  #   subnets           = var.private_subnet_ids 
  #   security_groups   = [aws_security_group.jenkins.id]
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.jenkins.arn
    container_name   = "jenkins"
    container_port   = 8080
  }
  
  depends_on = [aws_lb_target_group.jenkins]

  # (ノಠ益ಠ)ノ 彡┻━┻ PAID!!!

  # service_registries {
  #   registry_arn = aws_service_discovery_service.jenkins.arn
  #   port =  50000
  # }
}

resource "aws_ecs_task_definition" "jenkins" {
  family              = "jenkins"
  task_role_arn       = aws_iam_role.jenkins.arn
  execution_role_arn  = aws_iam_role.jenkins_execution.arn
  network_mode        = "bridge"

  container_definitions = jsonencode([
    {
      name      = "jenkins"
      image     = "medoth/jenkins-ansible:lts-jdk11"
      memoryReservation    = 900
      essential = true

      portMappings = [
        {
          containerPort =  8080,
          hostPort      = 8080
        },
        {
          containerPort = 50000,
          hostPort      = 50000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = aws_cloudwatch_log_group.jenkins.name,
          awslogs-region = data.aws_region.current.name,
          awslogs-stream-prefix =  "jenkins-master"
        }
      }

      mountPoints = [
        {
          sourceVolume = "jenkins-home",
          containerPath =  "/var/jenkins_home"
        }
      ]
    },
  ])

  volume {
    name = "jenkins-home"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.this.id
      }
    }
  }
}

resource "aws_efs_file_system" "this" {
  tags = {
    Terraform = "true"
  }
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/jenkins_home"
    creation_info {
      owner_gid   = var.efs_access_point_uid #1000 = jenkins user uid
      owner_uid   = var.efs_access_point_gid # needed for binding volume to jenkins_home in container
      permissions = "755"
    }
  }
}


# public subnets where ecs cluster located
# if using nat or fargate then it better be private
resource "aws_efs_mount_target" "efs-mount" {
   count              = length(var.public_subnet_ids)
   file_system_id     = aws_efs_file_system.this.id
   subnet_id          = element(var.public_subnet_ids, count.index)
   security_groups    = [aws_security_group.efs.id]
}

resource "aws_security_group" efs {
  name        = "efs-sg"
  description = "custom efs security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    cidr_blocks     = [data.aws_vpc.this.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform = "true"
  }
}