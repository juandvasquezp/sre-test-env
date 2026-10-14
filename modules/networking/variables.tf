variable "name_prefix" {
  description = "Prefijo usado para los tags Name de todos los recursos"
  type        = string
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
  description = "Mapa de AZ a CIDR para las subnets publicas"
  type        = map(string)

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
  description = "Mapa de AZ a CIDR para las subnets privadas"
  type        = map(string)

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "Debe existir al menos una subnet privada."
  }

  validation {
    condition     = alltrue([for cidr in values(var.private_subnet_cidrs) : can(cidrnetmask(cidr))])
    error_message = "Todos los valores de private_subnet_cidrs deben ser CIDRs IPv4 validos."
  }
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos del modulo"
  type        = map(string)
  default     = {}
}
