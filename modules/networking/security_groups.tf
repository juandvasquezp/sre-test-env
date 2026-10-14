#############################################
# Security Group de Lambda
# Egress unicamente hacia Redis en 6379
#############################################

resource "aws_security_group" "lambda" {
  name   = "${var.name_prefix}-lambda"
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-lambda-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_redis" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

#############################################
# Security Group de Redis
# Ingress unicamente desde Lambda en 6379
#############################################

resource "aws_security_group" "redis" {
  name   = "${var.name_prefix}-redis"
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_lambda" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}
