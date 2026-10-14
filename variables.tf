variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS CLI usado para autenticacion"
  type        = string
  default     = "personal"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para nombrar y etiquetar recursos"
  type        = string
  default     = "sre-interview"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser uno de: dev, staging, prod."
  }
}
