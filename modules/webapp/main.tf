data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
}

resource "aws_iam_role" "this" {
  name = "${var.name}-EC2-Role-${var.mandatory_tags.Environment}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = element(local.role_policy_arns, count.index)
}

resource "aws_iam_role_policy" "this" {
  name = "${var.name}-EC2-Inline-Policy-${var.mandatory_tags.Environment}"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter"
          ],
          "Resource" : "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/cloudwatch-agent/${var.mandatory_tags.Environment}/${var.name}-config"
        }
      ]
    }
  )
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-EC2-Profile-${var.mandatory_tags.Environment}"
  role = aws_iam_role.this.name
}


resource "aws_security_group" "ec2_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.name}-${var.mandatory_tags.Environment}-sg"
  description = "App security group"

  ingress {
    description     = "App port"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-${var.mandatory_tags.Environment}-sg"
    }
  )
}

resource "aws_ssm_parameter" "cw_agent" {
  description = "Cloudwatch agent config to configure custom log"
  name        = "/cloudwatch-agent/${var.mandatory_tags.Environment}/${var.name}-config"
  type        = "String"
  value       = file("${path.module}/${local.cw_agent_policy_filepath}")
  //value       = file("cw_agent_config.json")
  tags = var.mandatory_tags
}

data "template_file" "ec2_user_data" {
  template = file("${path.module}/${local.ec2_user_data_filepath}")
  vars = {
    app_port              = var.app_port
    fsa_api_base_url      = var.fsa_api_base_url
    ssm_cloudwatch_config = aws_ssm_parameter.cw_agent.name
  }
}

data "aws_ami" "ubuntu" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.name}-lt-${var.mandatory_tags.Environment}-${random_string.random.result}"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(data.template_file.ec2_user_data.rendered)
  tags = merge(
    var.mandatory_tags,
    {
      Name = "${var.name}-lt-${var.mandatory_tags.Environment}-${random_string.random.result}"
    }
  )
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "${aws_launch_template.app_lt.name}-asg"
  min_size            = 2
  desired_capacity    = 3
  max_size            = 4
  vpc_zone_identifier = var.private_subnets_ids

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = aws_launch_template.app_lt.latest_version
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  # tag {
  #   key                 = "Name"
  #   value               = "asg-${var.application}-${var.environment}"
  #   propagate_at_launch = true
  # }
}

resource "aws_autoscaling_policy" "cpu_scaling_policy" {
  name                      = "${var.name}-cpu-scaling-policy-${var.mandatory_tags.Environment}"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 20
  autoscaling_group_name    = aws_autoscaling_group.app_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}


resource "aws_autoscaling_attachment" "app_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  lb_target_group_arn    = aws_alb_target_group.alb_tg.arn
}
