## ECS Services

### Cluster

resource "aws_ecs_cluster" "my_services" {
  name = "my-services"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

### Instances

data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_configuration" "ecs" {
  image_id      = data.aws_ami.ecs.id
  instance_type = "t3.small"

  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.id

  security_groups = [aws_security_group.allow_all.id]

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=my-services >> /etc/ecs/ecs.config
              EOF
}

resource "aws_autoscaling_group" "ecs" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.ecs.id
  vpc_zone_identifier  = module.vpc.private_subnets

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceRole"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"
  path = "/"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}