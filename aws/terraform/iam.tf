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
