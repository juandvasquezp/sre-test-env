variable "name_prefix" {
  description = "Prefijo usado para los tags Name de todos los recursos"
  type        = string
}

variable "bucket_name" {
  description = "Nombre del bucket S3 de resultados"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN del rol IAM de la Lambda, unico principal autorizado"
  type        = string
}

variable "s3_vpc_endpoint_id" {
  description = "ID del VPC Endpoint Gateway de S3 para la condicion aws:SourceVpce"
  type        = string
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos del modulo"
  type        = map(string)
  default     = {}
}
