output "plan2_role_arn" {
    value = "arn:aws:iam::${aws_organizations_account.plan2.id}:role/${local.plan2_role_name}"
}

output "route53_role_arn" {
    value = aws_iam_role.external_route53_records.arn
}

output "certificate_arn" {
    value = aws_acm_certificate.cert.arn
}