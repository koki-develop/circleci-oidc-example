data "http" "circleci_openid_configuration" {
  url = "https://oidc.circleci.com/org/${var.circleci_organization_id}/.well-known/openid-configuration"
}

data "tls_certificate" "circleci" {
  url = jsondecode(data.http.circleci_openid_configuration.response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "circleci" {
  url             = "https://oidc.circleci.com/org/${var.circleci_organization_id}"
  client_id_list  = [var.circleci_organization_id]
  thumbprint_list = data.tls_certificate.circleci.certificates[*].sha1_fingerprint
}

data "aws_iam_policy_document" "circleci_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.circleci.arn]
    }
    condition {
      test     = "StringLike"
      variable = "oidc.circleci.com/org/${var.circleci_organization_id}:sub"
      values   = ["org/${var.circleci_organization_id}/project/${var.circleci_project_id}/user/*"]
    }
  }
}

resource "aws_iam_role" "circleci" {
  name               = "circleci-oidc-example-role"
  assume_role_policy = data.aws_iam_policy_document.circleci_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "circleci_s3_readonly" {
  role       = aws_iam_role.circleci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
