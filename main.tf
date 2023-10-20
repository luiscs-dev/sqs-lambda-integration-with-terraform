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
    type = map
    default = {
        dev = "us-east-1"
        prod = "us-east-1"
    }
}

provider "aws" {
    region = var.aws_region[terraform.workspace]
    profile = "aws-training"
}

data "archive_file" "myzip" {
    type = "zip"
    source_file = "main.py"
    output_path = "main.zip"
}

resource "aws_lambda_function" "sqs_reader_lambda" {
    filename = "main.zip"
    function_name = "sqs_reader_lambda_${terraform.workspace}"
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
    name = "sqs_lambda_role_${terraform.workspace}"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_sqs_queue" "main_queue" {
    name = "main-queue_${terraform.workspace}"
    delay_seconds = 30
    max_message_size = 262144
}

resource "aws_sqs_queue" "dl_queue" {
    name = "dl-queue_${terraform.workspace}"
    delay_seconds = 30
    max_message_size = 262144
}

resource "aws_lambda_event_source_mapping" "sqs-lambda-trigger" {
    event_source_arn = aws_sqs_queue.main_queue.arn
    function_name = aws_lambda_function.sqs_reader_lambda.arn
}

resource "aws_s3_bucket" "cs-tf-sqs-lambda-bucket" {
  bucket = "cs-tf-sqs-lambda-bucket"
}
