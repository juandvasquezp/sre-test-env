data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  }

  s3_results_bucket_name = "${var.project_name}-${var.environment}-results-${data.aws_caller_identity.current.account_id}"
}

module "networking" {
  source = "./modules/networking"

  name_prefix = "${var.project_name}-${var.environment}"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = local.common_tags
}

module "cache" {
  source = "./modules/cache"

  name_prefix             = "${var.project_name}-${var.environment}"
  private_subnet_ids      = values(module.networking.private_subnet_ids)
  redis_security_group_id = module.networking.redis_security_group_id
  tags                    = local.common_tags
}

module "logic" {
  source = "./modules/logic"

  name_prefix              = "${var.project_name}-${var.environment}"
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = values(module.networking.private_subnet_ids)
  lambda_security_group_id = module.networking.lambda_security_group_id
  redis_address            = module.cache.redis_endpoint_address
  redis_port               = module.cache.redis_endpoint_port
  s3_bucket_name           = local.s3_results_bucket_name
  tags                     = local.common_tags
}

module "storage" {
  source = "./modules/storage"

  name_prefix        = "${var.project_name}-${var.environment}"
  bucket_name        = local.s3_results_bucket_name
  lambda_role_arn    = module.logic.role_arn
  s3_vpc_endpoint_id = module.networking.s3_vpc_endpoint_id
  tags               = local.common_tags
}

module "communication" {
  source = "./modules/communication"

  name_prefix          = "${var.project_name}-${var.environment}"
  stage_name           = var.environment
  lambda_invoke_arn    = module.logic.invoke_arn
  lambda_function_name = module.logic.function_name
  tags                 = local.common_tags
}
