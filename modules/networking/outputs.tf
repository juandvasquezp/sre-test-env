output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "Bloque CIDR IPv4 de la VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets publicas por AZ"
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "public_subnet_cidrs" {
  description = "CIDRs de las subnets publicas por AZ"
  value       = { for az, subnet in aws_subnet.public : az => subnet.cidr_block }
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas por AZ"
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
}

output "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas por AZ"
  value       = { for az, subnet in aws_subnet.private : az => subnet.cidr_block }
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "nat_gateway_public_ip" {
  description = "IP elastica publica del NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "public_route_table_id" {
  description = "ID de la route table publica"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID de la route table privada"
  value       = aws_route_table.private.id
}
