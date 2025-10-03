# Generate a random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
}

# RDS database
resource "aws_db_instance" "strapi_db" {
  identifier           = "strapi-db"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "strapi"
  username             = var.rds_username
  password             = random_password.rds_password.result
  publicly_accessible  = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# ------------------------------
# Secrets Manager for ECS usage
# ------------------------------

# Store RDS username as a separate secret
resource "aws_secretsmanager_secret" "rds_username" {
  name = "strapi-rds-username"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_username_version" {
  secret_id     = aws_secretsmanager_secret.rds_username.id
  secret_string = var.rds_username
}

# Store RDS password as a separate secret
resource "aws_secretsmanager_secret" "rds_password" {
  name = "strapi-rds-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.rds_password.result
}
