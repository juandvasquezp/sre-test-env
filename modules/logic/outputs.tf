output "function_name" {
  description = "Nombre de la funcion Lambda"
  value       = aws_lambda_function.process.function_name
}

output "function_arn" {
  description = "ARN de la funcion Lambda"
  value       = aws_lambda_function.process.arn
}

output "invoke_arn" {
  description = "ARN de invocacion para usar en la integracion de API Gateway"
  value       = aws_lambda_function.process.invoke_arn
}

output "role_arn" {
  description = "ARN del rol de ejecucion de la Lambda"
  value       = aws_iam_role.lambda_execution.arn
}

output "log_group_name" {
  description = "Nombre del log group de CloudWatch de la Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}
