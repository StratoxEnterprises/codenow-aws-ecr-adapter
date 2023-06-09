provider "aws" {
  region     = var.provider_region
  access_key = var.aws_provider_client_id
  secret_key = var.aws_provider_client_secret
}

module "ecr" {
  source                                          = "./modules/create"
  count                                           = var.container_registry_enabled ? 1 : 0
  customer_name                                   = var.customer_name
  repositories                                    = var.container_registry_repositories
  image_mutability_default                        = var.container_registry_image_mutability_default
  image_scanning_default                          = var.container_registry_image_scanning_default
  image_retention_rule_quantity_to_retain_default = var.container_registry_image_retention_rule_quantity_to_retain_default
  allowed_read_principals                         = var.container_registry_allowed_read_principals
}