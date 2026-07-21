resource "aws_secretsmanager_secret" "db_secret" {
  name = "lab/rds/mysql/18"
    recovery_window_in_days = 0

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = "admin"
    password = "password123"
  })
}