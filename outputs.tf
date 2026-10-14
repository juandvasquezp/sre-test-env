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
