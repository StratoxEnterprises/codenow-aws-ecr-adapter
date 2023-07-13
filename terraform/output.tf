output "container_registry_repositories" {
  value = module.ecr.*.repositories
}
