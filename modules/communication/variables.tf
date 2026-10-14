variable "name_prefix" {
  description = "Prefijo usado para los tags Name de todos los recursos"
  type        = string
}

variable "stage_name" {
  description = "Nombre del stage de API Gateway"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "ARN de invocacion de la Lambda para la integracion proxy"
  type        = string
}

variable "lambda_function_name" {
  description = "Nombre de la funcion Lambda que se invoca"
  type        = string
}

variable "throttling_rate_limit" {
  description = "Rate limit (solicitudes por segundo) a nivel de stage"
  type        = number
  default     = 100
}

variable "throttling_burst_limit" {
  description = "Burst limit (maximo de solicitudes en rafaga) a nivel de stage"
  type        = number
  default     = 200
}

variable "log_retention_in_days" {
  description = "Retencion en dias de los access logs en CloudWatch"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos del modulo"
  type        = map(string)
  default     = {}
}
