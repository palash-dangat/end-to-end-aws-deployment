resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.ec2_sg.id]
    subnet_id                   = aws_subnet.private_1.id
    associate_public_ip_address = false
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              curl -sL https://rpm.nodesource.com/setup_18.x | bash -
              yum install -y nodejs git
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "asg-backend-instance" }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg"
  min_size            = 2
  max_size            = 5
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-backend"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type             = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}