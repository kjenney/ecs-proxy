### Resources required to create and host ECS Service - second

resource "aws_ecs_service" "second" {
  name = "second"
  cluster = aws_ecs_cluster.my_services.id
  task_definition = aws_ecs_task_definition.second_task_definition.arn
  desired_count = 1
}

resource "aws_ecs_task_definition" "second_task_definition" {
  family = "second"
  container_definitions = jsonencode([
    {
      name      = "second"
      image     = "nginx"
      cpu       = 1
      memory    = 512
      portMappings = [
        {
          containerPort = 80
          hostPort      = 8081
        }
      ]
    }
  ])
}

resource "aws_autoscaling_attachment" "second" {
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  lb_target_group_arn   = aws_lb_target_group.second.arn
}

resource "aws_lb_target_group" "second" {
  name     = "second-ecs-service-target-group"
  port     = 8081
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "second" {
  load_balancer_arn = aws_lb.my_nlb.arn
  port              = "8081"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.second.arn
  }
}
