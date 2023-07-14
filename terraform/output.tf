output "container_registry_repositories" {
  value = module.ecr.*.repositories
}

output "container_registry_user_writer_username" {
  value = module.ecr.*.repository_user_writer_username
  sensitive = true
}

output "container_registry_user_writer_password" {
  value = module.ecr.*.repository_user_writer_password
  sensitive = true
}