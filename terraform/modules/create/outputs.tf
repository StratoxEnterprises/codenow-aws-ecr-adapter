output "repositories" {
  value = [
    for name in(var.repositories) : aws_ecr_repository.default[name].repository_url
  ]
}

output "repository_user_writer_username" {
  value = aws_iam_access_key.ecr-writer.id
}

output "repository_user_writer_password" {
  value = aws_iam_access_key.ecr-writer.secret
}