variable "name_prefix" {
  description = "Prefijo usado para los tags Name de todos los recursos"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas donde se despliega Redis"
  type        = list(string)
}

variable "redis_security_group_id" {
  description = "ID del security group que restringe el acceso a Redis"
  type        = string
}

variable "node_type" {
  description = "Tipo de nodo de ElastiCache"
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Version del engine Redis"
  type        = string
  default     = "7.1"
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos del modulo"
  type        = map(string)
  default     = {}
}
