resource "aws_vpc" "project1" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "project1"
  }
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.project1.id
  map_public_ip_on_launch = true
  cidr_block              = var.sub1_cidr
  availability_zone       = "us-east-1a"
  tags = {
    Name = "sub-01"
  }
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.project1.id
  map_public_ip_on_launch = true
  cidr_block              = var.sub2_cidr
  availability_zone       = "us-east-1b"
  tags = {
    Name = "sub-02"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project1.id
  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.project1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Route_table"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt1.id
}
resource "aws_security_group" "terra_sg" {
  vpc_id      = aws_vpc.project1.id
  name        = "myterra-sg"
  description = "sg for ports 80,443,22"
  dynamic "ingress" {
    for_each = [80, 22, 443]
    iterator = ports
    content {
      to_port     = ports.value
      from_port   = ports.value
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  }
  egress {
    to_port     = "0"
    from_port   = "0"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }
}

data "aws_key_pair" "mykey" {
  key_name           = "ansible_test"
  include_public_key = true
}

resource "aws_instance" "myec-1" {
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  subnet_id              = aws_subnet.sub1.id
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = var.instance_id
  tags = {
    Name = "Vishal1"
  }
  associate_public_ip_address = true
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = true
  }
  key_name  = data.aws_key_pair.mykey.key_name
  user_data = base64encode(file("/devops/terraform/project1/user_data.sh"))
}

resource "aws_instance" "myec_2" {
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  subnet_id              = aws_subnet.sub2.id
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = var.instance_id
  tags = {
    Name = "Vishal2"
  }
  associate_public_ip_address = true
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = true
  }
  key_name  = data.aws_key_pair.mykey.key_name
  user_data = base64encode(file("/devops/terraform/project1/user_data1.sh"))
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "mys3" {
  bucket = "mynews3bucketforproject1-terraform"
  tags = {
    Name = "mynews3bucketforproject1-terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_access" {
  bucket = aws_s3_bucket.mys3.id

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
}

resource "aws_s3_bucket_policy" "lb-bucket-policy" {
  bucket = aws_s3_bucket.mys3.id
  policy = <<POLICY
{
  "Id": "testPolicy1561031527701",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "testStmt1561031516716",
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::mynews3bucketforproject1-terraform/lb-logs/*",
      "Principal": {
        "AWS": [
           "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}

resource "aws_lb_target_group" "project1_tg" {
  name             = "target-group-1"
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  health_check {
    protocol = "HTTP"
    path     = "/"
  }
  vpc_id = aws_vpc.project1.id
}

resource "aws_lb_target_group_attachment" "project1_tgattach" {
  target_group_arn = aws_lb_target_group.project1_tg.arn
  target_id        = aws_instance.myec-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "project1_tgattach1" {
  target_group_arn = aws_lb_target_group.project1_tg.arn
  target_id        = aws_instance.myec_2.id
  port             = 80
}

resource "aws_lb_listener" "project1_lsnr" {
  load_balancer_arn = aws_lb.project1_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project1_tg.arn
  }
}

resource "aws_lb" "project1_lb" {
  name               = "project1-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terra_sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  access_logs {
    bucket = aws_s3_bucket.mys3.id
    prefix = "lb-logs"
    enabled = true
  }
  tags = {
    Name = "Production"
  }
}

output "albdns" {
  value = aws_lb.project1_lb.dns_name
}
