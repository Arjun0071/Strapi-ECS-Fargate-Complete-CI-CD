resource "random_password" "strapi_secrets" {
  for_each = {
    APP_KEYS            = 64
    JWT_SECRET          = 64
    ADMIN_JWT_SECRET    = 64
    API_TOKEN_SALT      = 64
    TRANSFER_TOKEN_SALT = 64
    ENCRYPTION_KEY      = 64
  }

  length  = each.value
  special = true
}

resource "aws_secretsmanager_secret" "strapi_secrets" {
  for_each = random_password.strapi_secrets
  name     = each.key
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "strapi_secrets_version" {
  for_each      = aws_secretsmanager_secret.strapi_secrets
  secret_id     = each.value.id
  secret_string = random_password.strapi_secrets[each.key].result
}
