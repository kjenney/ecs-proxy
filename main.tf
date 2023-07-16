provider "aws" {
  region = "us-east-1"
}

# VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "complete-example"

  cidr = "10.10.0.0/16"

  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets      = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]

  create_database_subnet_group = false

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Owner       = "user"
    Environment = "staging"
    Name        = "complete"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NLB

resource "aws_lb" "my_nlb" {
  name = "my-nlb"
  load_balancer_type = "network"
  subnets = module.vpc.public_subnets
}

## NLB Listeners

### First Service Listener

resource "aws_lb_target_group" "first" {
  name     = "first-ecs-service-target-group"
  port     = 8080
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_nlb.arn
  port              = "8080"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.first.arn
  }
}

## ECS Services

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

resource "aws_autoscaling_attachment" "first" {
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  lb_target_group_arn   = aws_lb_target_group.first.arn
}

### Cluster

resource "aws_ecs_cluster" "my_services" {
  name = "my-services"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

### First Service

resource "aws_ecs_service" "first" {
  name = "first"
  cluster = aws_ecs_cluster.my_services.id
  task_definition = aws_ecs_task_definition.first_task_definition.arn
  desired_count = 1
}

resource "aws_ecs_task_definition" "first_task_definition" {
  family = "first"
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "nginx"
      cpu       = 1
      memory    = 512
      portMappings = [
        {
          containerPort = 80
          hostPort      = 8080
        }
      ]
    }
  ])
}

