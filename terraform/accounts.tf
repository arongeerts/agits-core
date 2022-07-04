locals {
    plan2_role_name = "plan2-organizations-role"
}

data "aws_organizations_organization" "agits" {}

resource "aws_organizations_organizational_unit" "plan2" {
    name      = "plan2"
    parent_id = data.aws_organizations_organization.agits.roots[0].id
}

resource "aws_organizations_account" "plan2" {
    name      = "plan2"
    email     = "arongeerts8+awsplan2@gmail.com"
    iam_user_access_to_billing = "ALLOW"
    parent_id = aws_organizations_organizational_unit.plan2.id

    role_name = local.plan2_role_name

    tags = {
        "Project": "plan2"
        "Contact": "alain@planbv.be"
    }

    lifecycle {
        ignore_changes = [role_name]
    }
}