resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name_prefix}-redis"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-subnet-group"
  })
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.name_prefix}-redis"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-ttl"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-params"
  })
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id               = "${var.name_prefix}-redis"
  engine                   = "redis"
  node_type                = var.node_type
  num_cache_nodes          = 1
  engine_version           = var.engine_version
  port                     = 6379
  parameter_group_name     = aws_elasticache_parameter_group.redis.name
  subnet_group_name        = aws_elasticache_subnet_group.redis.name
  security_group_ids       = [var.redis_security_group_id]
  snapshot_retention_limit = 0

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
  })
}
