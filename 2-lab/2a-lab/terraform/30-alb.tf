### APPLICATION LOAD BALANCER (Bonus-B)
resource "aws_lb" "alb_bonus_b" {
  name               = "bonusb-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb_bonus_b.id]
  subnets = [
    aws_subnet.public_subnet_resource.id,
    aws_subnet.public_subnet_b_resource.id
  ]

  tags = {
    Name = "bonusb-alb01"
  }
}

### TARGET GROUP
# Points at the Bonus-A private EC2 on port 80 (where the Flask app listens).
resource "aws_lb_target_group" "tg_bonus_b" {
  name     = "bonusb-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_resource.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "bonusb-tg01"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach_private_ec2" {
  target_group_arn = aws_lb_target_group.tg_bonus_b.arn
  target_id        = aws_instance.ec2_private.id
  port             = 80
}
