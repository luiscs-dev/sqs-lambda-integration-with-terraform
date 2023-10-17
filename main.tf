terraform {
    required_version = ">= 0.12"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 5.20"
        }
    }
}

variable "aws_region" {
    type = string
    default = "us-east-1"
}

provider "aws" {
    region = var.aws_region
    profile = "aws-training"
}

data "archive_file" "myzip" {
    type = "zip"
    source_file = "main.py"
    output_path = "main.zip"
}

resource "aws_lambda_function" "sqs_reader_lambda" {
    filename = "main.zip"
    function_name = "sqs_reader_lambda"
    role = aws_iam_role.sqs_lambda_role.arn
    handler = "main.lambda_handler"
    runtime = "python3.10"
    source_code_hash = data.archive_file.myzip.output_base64sha256
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sqs_lambda_role" {
    name = "sqs_lambda_role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
