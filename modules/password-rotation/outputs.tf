output "lambda_function_name" {
  value = aws_lambda_function.password_rotation.function_name
}

output "secret_arns" {
  value = {
    for k, v in aws_secretsmanager_secret.windows_password : k => v.arn
  }
}
