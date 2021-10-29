data "aws_partition" "current" {}

# IAM for ecs instance
resource "aws_iam_role" "ecs" {
  name = "iam_role_ecs-${substr(var.ecs_cluster_name, 0, 10)}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs" {
  name = "iam_profile_ecs-${substr(var.ecs_cluster_name, 0, 10)}"
  role = aws_iam_role.ecs.name
}

resource "aws_iam_role_policy_attachment" "ecs_for_ec2" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}