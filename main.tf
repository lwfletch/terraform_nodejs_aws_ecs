# This file launchs one vpc with one subnet and security group in order to
# launch one ECS cluster, service and task definition
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "tf_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "tf_vpc"
  }
}

resource "aws_internet_gateway" "tf_vpc_igw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "tf_vpc_igw"
  }
}

resource "aws_route" "tf_vpc_route" {
  route_table_id  = aws_vpc.tf_vpc.main_route_table_id
  gateway_id      = aws_internet_gateway.tf_vpc_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "tf_vpc_public_subnet1" {
  vpc_id      = aws_vpc.tf_vpc.id
  cidr_block  = "10.0.1.0/24"
  map_public_ip_on_launch = true //it makes this a public subnet
  availability_zone = "us-east-1a"
  tags = {
    Name = "tf_vpc_public_subnet1"
  }
}

resource "aws_subnet" "tf_vpc_private_subnet1" {
  vpc_id      = aws_vpc.tf_vpc.id
  cidr_block  = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "tf_vpc_private_subnet1"
  }
}

resource "aws_security_group" "tf_vpc_sg" {
  vpc_id      = aws_vpc.tf_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "out_all"
  }

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    description = "in_all"
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "in_http"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "trey-tf-node-cluster"
}

resource "aws_ecs_service" "main" {
 name                               = "trey-tf-node-service"
 cluster                            = aws_ecs_cluster.main.id
 task_definition                    = aws_ecs_task_definition.main.arn
 desired_count                      = 1
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 200
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"

 network_configuration {
   security_groups  = [aws_security_group.tf_vpc_sg.id]
   subnets          = [aws_subnet.tf_vpc_public_subnet1.id]
   assign_public_ip = true
 }
}

resource "aws_ecs_task_definition" "main" {
  family = "trey-tf-node-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = "arn:aws:iam::752436870060:role/trey-ecs-node-api-role-123"
  task_role_arn = "arn:aws:iam::752436870060:role/trey-ecs-node-api-role-123"
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([{
   name        = "trey-tf-nodejs-container"
   image       = "752436870060.dkr.ecr.us-east-1.amazonaws.com/node-tf-ecs-example:latest"
   essential   = true,
   portMappings = [{
     protocol      = "tcp"
     containerPort = 8081
     hostPort      = 8081
    }]
  }])
}