output "invoke_url" {
  description = "URL base de invocacion del stage"
  value       = aws_api_gateway_stage.process_api.invoke_url
}

output "process_endpoint" {
  description = "Endpoint completo de POST /process"
  value       = "${aws_api_gateway_stage.process_api.invoke_url}/process"
}

output "rest_api_id" {
  description = "ID de la REST API"
  value       = aws_api_gateway_rest_api.process_api.id
}

output "stage_name" {
  description = "Nombre del stage desplegado"
  value       = aws_api_gateway_stage.process_api.stage_name
}

output "execution_arn" {
  description = "Execution ARN del stage"
  value       = aws_api_gateway_stage.process_api.execution_arn
}
