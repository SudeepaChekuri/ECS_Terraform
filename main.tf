provider "aws" {
  region = "ap-south-1"  # Replace with your desired AWS region
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-ecr-repo"
}

# Data source to retrieve the Docker image URL from ECR
data "aws_ecr_image" "my_ecr_image" {
  name         = aws_ecr_repository.my_ecr_repo.name
  image_tag    = "latest"
  registry_id  = aws_ecr_repository.my_ecr_repo.registry_id
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-family"
  container_definitions    = jsonencode([{
    name      = "my-web-app"
    image     = data.aws_ecr_image.my_ecr_image.image_uris[0]
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options   = {
        "awslogs-group"         = "/ecs/my-task-family"
        "awslogs-region"        = "ap-south-1"  # Replace with your desired AWS region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    environment = [
      {
        name  = "ENV_VAR1"
        value = "value1"
      },
      {
        name  = "ENV_VAR2"
        value = "value2"
      }
    ]
  }])
  requires_compatibilities = ["FARGATE"]
  memory                   = "512"
  cpu                      = "256"
}

resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"
}

