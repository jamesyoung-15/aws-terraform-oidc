provider "aws" {
  region = "us-east-1"
}

# create a new IAM OpenID Connect Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

# Policy Document for OIDC
data "aws_iam_policy_document" "oidc_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    condition {
      test     = "StringLike"
      values   = ["repo:jamesyoung-15/*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

# Iam Role for OIDC
resource "aws_iam_role" "oidc_role" {
  name               = "github_oidc_role"
  assume_role_policy = data.aws_iam_policy_document.oidc_policy.json
}

# Policy for OIDC Role to access AWS resources
data "aws_iam_policy" "deploy_policy" {
  arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "attach_deploy_policy" {
  policy_arn = data.aws_iam_policy.deploy_policy.arn
  role       = aws_iam_role.oidc_role.name
}