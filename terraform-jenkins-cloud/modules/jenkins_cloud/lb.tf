# alb
# Create a new load balancer with certificate (?????)
resource "tls_private_key" "jenkins" {
  algorithm   = "RSA"
}

resource "tls_self_signed_cert" "jenkins" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.jenkins.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 720

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "jenkins" {
  private_key      = tls_private_key.jenkins.private_key_pem
  certificate_body = tls_self_signed_cert.jenkins.cert_pem
}

resource "aws_lb" "jenkins" {
  name               = "jenkins-master-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_jenkins.id]
  subnets            = var.public_subnet_ids

  tags = {
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "jenkins" {
  name        = "jenkins-master-tg-${substr(uuid(), 0, 3)}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled = true
    path    = "/login"
    interval = 120
  }
  
  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }

  tags = {
    Terraform = "true"
  }
}

resource "aws_lb_listener" http {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 80
  protocol          = "HTTP"

  depends_on        = [aws_lb_target_group.jenkins] 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  # (ノಠ益ಠ)ノ 彡┻━┻ jenkins agent does not accept self signed cert

  # default_action {
  #   type = "redirect"

  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
}

resource "aws_lb_listener" https {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = aws_acm_certificate.jenkins.arn

  depends_on        = [aws_lb_target_group.jenkins]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}

resource "aws_security_group" "alb_jenkins" {
  name        = "sg_alb_jenkins"
  description = "for jenkins master alb"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol= "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform = "true"
  }
}
