provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

#############################
# VPC and Networking Setup
#############################

resource "aws_vpc" "chidera_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.chidera_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "chidera_igw" {
  vpc_id = aws_vpc.chidera_vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.chidera_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chidera_igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public.id
}

#############################
# Security Group
#############################

resource "aws_security_group" "chidera_sg" {
  name        = "chidera-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.chidera_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################
# EC2 Instances
#############################

resource "aws_instance" "web" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  key_name      = var.key_name
  security_groups = [aws_security_group.chidera_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from instance ${count.index + 1}</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "WebInstance-${count.index + 1}"
  }
}

#############################
# Elastic Load Balancer
#############################

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.chidera_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}


resource "aws_lb_target_group" "chidera_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.chidera_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chidera_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "chidera_tg_attachment" {
  count              = 3
  target_group_arn   = aws_lb_target_group.chidera_tg.arn
  target_id          = aws_instance.web[count.index].id
  port               = 80
}

#############################
# Export Public IPs
#############################

resource "null_resource" "export_ips" {
  provisioner "local-exec" {
    command = "echo '${join("\n", aws_instance.web[*].public_ip)}' > host-inventory"
  }

  depends_on = [aws_instance.web]
}

#############################
# Route53 DNS Record
#############################

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}
