variable "customer_name" {
  type = string
}

variable "repositories" {
  type = list(string)
}

variable "image_mutability_default" {
  type = string
}

variable "image_scanning_default" {
  type = bool
}

variable "image_retention_rule_quantity_to_retain_default" {
  type = number
}

variable "allowed_read_principals" {
  type = list(string)
}