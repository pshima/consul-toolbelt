provider "aws" {
  version = "~> 0.1.4"
  region  = "us-east-1"
}

resource "aws_security_group" "consul" {
  name   = "consul"
  vpc_id = "vpc-04f2ab7d"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_iam_instance_profile" "consul" {
    name = "consul"
    role = "${aws_iam_role.consul.name}"
}

resource "aws_iam_role_policy" "consul" {
    name = "consul"
    role = "${aws_iam_role.consul.name}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:Describe*",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "consul" {
    name = "consul"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_launch_configuration" "consul-servers" {
  image_id              = "ami-d61027ad"
  instance_type         = "t2.small"
  key_name              = "consul-toolbelt"
  security_groups       = ["${aws_security_group.consul.id}"]
  iam_instance_profile  = "consul"
  user_data = <<END
#!/bin/bash

ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

docker run -d \
  --net=host \
  -e 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true}' \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-1 \
  --log-opt awslogs-group=consul-toolbelt \
  consul agent -server \
    -bind "$ip" \
    -client 0.0.0.0 \
    -log-level trace \
    -bootstrap-expect 3 \
    -retry-join="provider=aws tag_key=Name tag_value=consul-servers" \
    -ui
END
}

resource "aws_autoscaling_group" "consul-servers" {
  name                  = "${aws_launch_configuration.consul-servers.name}"
  launch_configuration  = "${aws_launch_configuration.consul-servers.name}"
  desired_capacity      = "3"
  min_size              = "3"
  max_size              = "3"
  availability_zones    = ["us-east-1f"]
  vpc_zone_identifier   = ["subnet-8b3a7b87"]

  tag {
    key = "Name"
    value = "consul-servers"
    propagate_at_launch = true
  }
}


resource "aws_launch_configuration" "consul-clients" {
  image_id              = "ami-d61027ad"
  instance_type         = "t2.nano"
  key_name              = "consul-toolbelt"
  security_groups       = ["${aws_security_group.consul.id}"]
  iam_instance_profile  = "consul"
  user_data = <<END
#!/bin/bash

ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

docker run -d \
  --net=host \
  -e 'CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-1 \
  --log-opt awslogs-group=consul-toolbelt \
  consul agent \
    -bind "$ip" \
    -log-level trace \
    -retry-join="provider=aws tag_key=Name tag_value=consul-servers"

END
}

resource "aws_autoscaling_group" "consul-clients" {
  name                  = "${aws_launch_configuration.consul-clients.name}"
  launch_configuration  = "${aws_launch_configuration.consul-clients.name}"
  desired_capacity      = "50"
  min_size              = "50"
  max_size              = "50"
  availability_zones    = ["us-east-1f"]
  vpc_zone_identifier   = ["subnet-8b3a7b87"]

  tag {
    key = "Name"
    value = "consul-clients"
    propagate_at_launch = true
  }
}

