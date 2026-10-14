locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  }
}

module "networking" {
  source = "./modules/networking"

  name_prefix = "${var.project_name}-${var.environment}"

  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidrs = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }

  private_subnet_cidrs = {
    "us-east-1a" = "10.0.3.0/24"
    "us-east-1b" = "10.0.4.0/24"
  }

  tags = local.common_tags
}
