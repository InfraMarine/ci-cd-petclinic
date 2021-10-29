data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

# autoscaling group + launch template
resource "aws_launch_template" "this" {
  image_id                = var.image_id == "" ? data.aws_ami.ecs_ami.id : var.image_id
  instance_type           = var.instance_type
  key_name                = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  network_interfaces {
    security_groups             = concat([aws_security_group.this.id], var.sg_ids)
  }

  user_data = base64encode(
    templatefile("${path.module}/templates/user_data.sh", {ecs_cluster_name = var.ecs_cluster_name})
  )
}

resource "aws_autoscaling_group" "this" {
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [desired_capacity]
  }

  tag {
    key = "Terraform"
    value = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_security_group" this {
  name        = "asg_for_ecs_sg"
  description = "for ec2 instances in asg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
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