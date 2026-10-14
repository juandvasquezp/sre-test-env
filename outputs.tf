output "vpc_id" {
  description = "ID de la VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "Bloque CIDR IPv4 de la VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas por AZ"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas por AZ"
  value       = module.networking.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = module.networking.nat_gateway_id
}

output "process_endpoint" {
  description = "Endpoint completo de POST /process"
  value       = module.communication.process_endpoint
}

output "lambda_function_name" {
  description = "Nombre de la funcion Lambda"
  value       = module.logic.function_name
}

output "lambda_role_arn" {
  description = "ARN del rol de ejecucion de la Lambda"
  value       = module.logic.role_arn
}

output "redis_endpoint_address" {
  description = "Direccion del endpoint de Redis"
  value       = module.cache.redis_endpoint_address
}

output "redis_endpoint_port" {
  description = "Puerto del endpoint de Redis"
  value       = module.cache.redis_endpoint_port
}

output "s3_results_bucket_name" {
  description = "Nombre del bucket S3 de resultados"
  value       = module.storage.bucket_name
}
