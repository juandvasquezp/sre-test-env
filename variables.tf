variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS CLI usado para autenticacion. En null se usa la cadena de credenciales por defecto (AWS_PROFILE, variables de entorno o perfil default)"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "Bloque CIDR IPv4 de la VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr debe ser un bloque CIDR IPv4 valido (ej. 10.0.0.0/16)."
  }
}

variable "public_subnet_cidrs" {
  description = "Mapa de AZ a CIDR para las subnets publicas. Si cambias aws_region, ajusta las AZs"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "Debe existir al menos una subnet publica."
  }

  validation {
    condition     = alltrue([for cidr in values(var.public_subnet_cidrs) : can(cidrnetmask(cidr))])
    error_message = "Todos los valores de public_subnet_cidrs deben ser CIDRs IPv4 validos."
  }
}

variable "private_subnet_cidrs" {
  description = "Mapa de AZ a CIDR para las subnets privadas. Si cambias aws_region, ajusta las AZs"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.3.0/24"
    "us-east-1b" = "10.0.4.0/24"
  }

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "Debe existir al menos una subnet privada."
  }

  validation {
    condition     = alltrue([for cidr in values(var.private_subnet_cidrs) : can(cidrnetmask(cidr))])
    error_message = "Todos los valores de private_subnet_cidrs deben ser CIDRs IPv4 validos."
  }
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
