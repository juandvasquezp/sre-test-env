variable "name_prefix" {
  description = "Prefijo usado para los tags Name de todos los recursos"
  type        = string
}

variable "function_name" {
  description = "Nombre base de la funcion Lambda"
  type        = string
  default     = "process"
}

variable "vpc_id" {
  description = "ID de la VPC donde se despliega la Lambda"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas donde se despliega la Lambda"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "ID del security group de la Lambda (gestionado por el modulo de networking)"
  type        = string
}

variable "redis_address" {
  description = "Direccion del endpoint de Redis"
  type        = string
}

variable "redis_port" {
  description = "Puerto del endpoint de Redis"
  type        = number
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 donde la Lambda persiste los resultados"
  type        = string
}

variable "lambda_memory_size" {
  description = "Memoria asignada a la Lambda en MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout de la Lambda en segundos"
  type        = number
  default     = 10
}

variable "log_retention_in_days" {
  description = "Retencion en dias de los logs de la Lambda en CloudWatch"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos del modulo"
  type        = map(string)
  default     = {}
}
