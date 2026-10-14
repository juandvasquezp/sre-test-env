output "redis_endpoint_address" {
  description = "Direccion del endpoint de Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_endpoint_port" {
  description = "Puerto del endpoint de Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "redis_cluster_id" {
  description = "ID del cluster de ElastiCache"
  value       = aws_elasticache_cluster.redis.cluster_id
}

output "redis_arn" {
  description = "ARN del cluster de ElastiCache"
  value       = aws_elasticache_cluster.redis.arn
}
