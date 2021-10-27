resource "aws_ecs_task_definition" "inbound_agent_dind" {
  family              = "jenkins-inbound-dind"
  execution_role_arn  = aws_iam_role.jenkins_execution.arn
  network_mode        = "bridge"

  container_definitions = jsonencode([
    {
      name                = "inbound-agent-dind"
      image               = "diegolima/jenkins-inbound-dind:latest"
      memoryReservation   = 800
      privileged          = true
      
      portMappings = [
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = aws_cloudwatch_log_group.jenkins.name,
          awslogs-region = data.aws_region.current.name,
          awslogs-stream-prefix =  "jenkins-inbound-dind"
        }
      }

      mountPoints = [
        {
          sourceVolume = "user-home",
          containerPath =  "/home/jenkins/"
        },
        {
          sourceVolume = "host-docker",
          containerPath =  "/var/run/docker.sock"
        }
      ]
    },
  ])

  volume {
    name      = "host-docker"
    host_path = "/var/run/docker.sock"
  }

  volume {
    name = "user-home"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.home.id
      }
    }
  }
}

# volume to preserve maven dependancies (home/jenkins/.m2)

resource "aws_efs_access_point" "home" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/user_home"
    creation_info {
      owner_gid   = var.efs_access_point_uid #1000 = jenkins user uid
      owner_uid   = var.efs_access_point_gid # needed for binding volume to jenkins_home in container
      permissions = "777"   # UwU
    }
  }
}