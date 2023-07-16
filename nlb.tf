# NLB

resource "aws_lb" "my_nlb" {
  load_balancer_type = "network"
  subnets = module.vpc.public_subnets
}

## NLB Listeners are in each ECS service .tf file