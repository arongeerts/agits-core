terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.15"
        }
    }

    required_version = "~> 1.2"

    backend "s3" {
        bucket = "agits-infra-bucket"
        key    = "agits-core/terraform.tfstate"
        region = "eu-west-1"
    }
}

provider "aws" {
    region = "eu-west-1"
}

provider "aws" {
    alias  = "route53"
    region = "us-east-1"
}