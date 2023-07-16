### Resources required to create and host ECS Service - first

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
      mountPoints = [
        {
          sourceVolume  = "nginx-html"
          containerPath = "/usr/share/nginx/html"
        }
      ]
    }
  ])
  volume {
    name      = "nginx-html"
    host_path = "/tmp/html/first"
  }
}

resource "aws_autoscaling_attachment" "first" {
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  lb_target_group_arn   = aws_lb_target_group.first.arn
}

resource "aws_lb_target_group" "first" {
  name     = "first-ecs-service-target-group"
  port     = 8080
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "first" {
  load_balancer_arn = aws_lb.my_nlb.arn
  port              = "8080"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.first.arn
  }
}
