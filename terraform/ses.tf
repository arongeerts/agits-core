resource "aws_ses_domain_identity" "agits" {
    domain = local.domain_name
}

resource "aws_route53_record" "amazonses_verification" {
    zone_id = data.aws_route53_zone.agits.zone_id
    name    = "_amazonses.${local.domain_name}"
    type    = "TXT"
    ttl     = "600"
    records = [aws_ses_domain_identity.agits.verification_token]
}

resource "aws_ses_domain_identity_verification" "amazonses_verification" {
  domain = aws_ses_domain_identity.agits.id

  depends_on = [aws_route53_record.amazonses_verification]
}

resource "aws_sns_topic" "raw_mail" {
    name = "raw-mail"
}

resource "aws_sns_topic" "clean_mail" {
    name = "clean-mail"
}

resource "aws_s3_bucket" "agits_mail_archive" {
    name = "agits-mail-archive"
}

resource "aws_iam_role" "lambda_email_sender" {
    name = "lambda-email-sender"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_allow" {
    name = "allow-email-sender"
    path = "/"
    policy = jsonencode({
        Version   = "2012-10-17"
        Statement = [
            {
                Action = ["sns:*"]
                Effect   = "Allow"
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_policy_attachment" "lambda_allow" {
    name       = "allow-sns"
    roles      = [aws_iam_role.lambda_email_sender]
    policy_arn = aws_iam_policy.lambda_allow
}

resource "aws_lambda_permission" "sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_sender
  principal     = "sns.amazonaws.com"
  statement_id  = "AllowSubscriptionToSNS"
  source_arn    = aws_sns_topic.raw_mail
}

resource "aws_lambda_function" "email_sender" {
    // TODO
}
# Lambda function for cleaning mail
# SES Recipient rule
# SNS SES subscription on clean topic