resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_caller_identity" "current" {}

# Attach Secrets Manager access policy
resource "aws_iam_role_policy" "ecsTaskExecutionRole_secrets_policy" {
  name   = "ecsTaskExecutionRoleSecretsPolicy"
  role   = aws_iam_role.ecsTaskExecutionRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:APP_KEYS-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:JWT_SECRET-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:ADMIN_JWT_SECRET-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:API_TOKEN_SALT-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:TRANSFER_TOKEN_SALT-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:ENCRYPTION_KEY-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:strapi-rds-username-*",
          "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:strapi-rds-password-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecsTaskRole" {
  name = "ecsTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskRole.arn

  container_definitions = jsonencode([{
    name      = "strapi"
    image     = "${var.image_name}:${var.image_tag}"
    essential = true
    portMappings = [{
      containerPort = 1337
      protocol      = "tcp"
    }]

    # Environment variables for Strapi + Postgres
    environment = [
      { name = "NODE_ENV",        value = "production" },
      { name="STRAPI_ADMIN_BACKEND_URL",  value = "http://${aws_lb.alb.dns_name}:1337" },
      { name = "DATABASE_CLIENT", value = "postgres" },
      { name = "DATABASE_HOST",   value = aws_db_instance.strapi_db.address },
      { name = "DATABASE_PORT",   value = "5432" },
      { name = "DATABASE_NAME",   value = "strapi" },
      { name = "DATABASE_SSL",    value = "true" },
      { name = "DATABASE_SSL_REJECT_UNAUTHORIZED", value = "false" }
    ]

    # Secrets from Secrets Manager
    secrets = concat(
      [
        for k, v in aws_secretsmanager_secret.strapi_secrets : {
          name      = k
          valueFrom = v.arn
        }
      ],
      [
        {
          name      = "DATABASE_USERNAME"
          valueFrom = aws_secretsmanager_secret.rds_username.arn
        },
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.rds_password.arn
        }
      ]
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.strapi.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }
}
