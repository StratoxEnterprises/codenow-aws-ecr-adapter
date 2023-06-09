locals {
  tags = {
    customer = var.customer_name
  }
}

resource "aws_ecr_repository" "default" {
  for_each             = toset(var.repositories)
  name                 = each.value
  image_tag_mutability = var.image_mutability_default

  image_scanning_configuration {
    scan_on_push = var.image_scanning_default
  }

  tags = local.tags
}

resource "aws_iam_user" "ecr-writer" {
  name = format("%s-%s", var.customer_name, "default-ecr-writer")
  tags = local.tags
}

resource "aws_iam_user_policy" "ecr-writer" {
  name   = "default-ecr-writer-authorization-policy"
  user   = aws_iam_user.ecr-writer.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "ecr-writer" {
  user = aws_iam_user.ecr-writer.name
}

data "aws_iam_policy_document" "read-policy" {
  count = length(var.allowed_read_principals) > 0 ? 1 : 0
  statement {
    sid    = "read access to the repository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]
    principals {
      identifiers = var.allowed_read_principals
      type        = "AWS"
    }
  }
}

data "aws_iam_policy_document" "read-write-policy" {
  source_json = length(data.aws_iam_policy_document.read-policy) > 0 ? data.aws_iam_policy_document.read-policy[0].json : ""
  statement {
    sid    = "read write access to the repository"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:BatchDeleteImage"
    ]

    principals {
      identifiers = [aws_iam_user.ecr-writer.arn]
      type        = "AWS"
    }
  }
}

resource "aws_ecr_repository_policy" "default-policy" {
  for_each   = toset(var.repositories)
  repository = aws_ecr_repository.default[each.value].name
  policy     = data.aws_iam_policy_document.read-write-policy.json
}

resource "aws_ecr_lifecycle_policy" "default" {
  for_each   = toset(var.repositories)
  repository = aws_ecr_repository.default[each.value].name

  policy = <<EOF
  {
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last ${var.image_retention_rule_quantity_to_retain_default} images.",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.image_retention_rule_quantity_to_retain_default}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
  }
  EOF
}