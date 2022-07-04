locals {
    domain_name                        = "agits.be"
    external_route53_records_role_name = "external-route53-records"
    external_account_ids               = [
        aws_organizations_account.plan2.id
    ]
}

data "aws_route53_zone" "agits" {
    name          = local.domain_name
    private_zone  = false
}

resource "aws_iam_role" "external_route53_records" {
    name               = local.external_route53_records_role_name
    description        = "Allow child accounts in this organizations to create DNS records in the domain"
    assume_role_policy = jsonencode({
        Version   = "2012-10-17"
        Statement = [
            for account_id in local.external_account_ids : {
                Action   = "sts:AssumeRole"
                Effect   = "Allow"
                Sid      = ""
                Principal =  {
                    AWS = "arn:aws:iam::${account_id}:root"
                }
            } 
        ]
    })
}

resource "aws_iam_role_policy" "allow_route53" {
    name = "allow-route53-record-operations"
    role = aws_iam_role.external_route53_records.id

    policy = jsonencode({
        Version   = "2012-10-17"
        Statement = [
            {
                Action    = [
                    "route53:ListHostedZones",
                    "route53:GetChange"
                ],
                Effect    = "Allow"
                Sid       = "1"
                Resource = ["*"]
            },
            {
                Action    = [
                    "route53:ChangeResourceRecordSets",
                    "route53:GetHostedZone",
                    "route53:ListResourceRecordSets",
                    "route53:ListTagsForResource"
                ]
                Effect    = "Allow"
                Sid       = "2"
                Resource = [data.aws_route53_zone.agits.arn]
            }
        ]
    })
}

resource "aws_acm_certificate" "cert" {
  provider = aws.route53

  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.route53
  
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.agits.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.route53

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}