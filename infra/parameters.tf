resource "aws_ssm_parameter" "POSTGRES_HOST" {
  name        = "/prd/api/POSTGRES_HOST"
  type        = "SecureString"
  value       = module.db.db_instance_address

  tags = {
    environment = "production"
  }
}
resource "aws_ssm_parameter" "POSTGRES_DB" {
  name        = "/prd/api/POSTGRES_DB"
  type        = "SecureString"
  value       = "api"

  tags = {
    environment = "production"
  }
}
resource "aws_ssm_parameter" "POSTGRES_PASSWORD" {
  name        = "/prd/api/POSTGRES_PASSWORD"
  type        = "SecureString"
  value       = random_password.complex.result

  tags = {
    environment = "production"
  }
}
resource "aws_ssm_parameter" "POSTGRES_PORT" {
  name        = "/prd/api/POSTGRES_PORT"
  type        = "SecureString"
  value       = "5432"

  tags = {
    environment = "production"
  }
}
resource "aws_ssm_parameter" "POSTGRES_USER" {
  name        = "/prd/api/POSTGRES_USER"
  type        = "SecureString"
  value       = "api"

  tags = {
    environment = "production"
  }
}