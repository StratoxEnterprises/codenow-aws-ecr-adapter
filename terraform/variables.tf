variable "aws_provider_client_id" {
  type        = string
  description = "The AWS access key."
}

variable "aws_provider_client_secret" {
  type        = string
  description = "The AWS secret key."
}

variable "provider_region" {
  type    = string
  default = "eu-central-1"
}


variable "customer_name" {
  type        = string
  description = "The name of Customer (e.g. packeta)."
}

variable "environment_name" {
  type        = string
  description = "The name of environment (e.g. stage)."
}

variable "container_registry_enabled" {
  type    = bool
  default = false
}

variable "container_registry_repositories" {
  type    = list(string)
  default = []
}

variable "container_registry_allowed_read_principals" {
  type    = list(string)
  default = []
}

variable "container_registry_image_mutability_default" {
  type    = string
  default = "IMMUTABLE"
}

variable "container_registry_image_scanning_default" {
  type    = bool
  default = false
}

variable "container_registry_image_retention_rule_quantity_to_retain_default" {
  type    = number
  default = 10
}