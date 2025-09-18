terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket for storing synthesized speech
resource "aws_s3_bucket" "pollibi_audio" {
  bucket = "${var.project_name}-audio-${random_id.suffix.hex}"

  tags = {
    Name        = "${var.project_name}-audio"
    Environment = var.environment
    Project     = "POLLIBI"
  }
}

resource "aws_s3_bucket_ownership_controls" "pollibi_audio" {
  bucket = aws_s3_bucket.pollibi_audio.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "pollibi_audio" {
  depends_on = [aws_s3_bucket_ownership_controls.pollibi_audio]
  bucket     = aws_s3_bucket.pollibi_audio.id
  acl        = "private"
}

# S3 Bucket for frontend hosting
resource "aws_s3_bucket" "pollibi_frontend" {
  bucket = "${var.project_name}-frontend-${random_id.suffix.hex}"

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
    Project     = "POLLIBI"
  }
}

resource "aws_s3_bucket_website_configuration" "pollibi_frontend" {
  bucket = aws_s3_bucket.pollibi_frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "pollibi_frontend" {
  bucket = aws_s3_bucket.pollibi_frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "pollibi_frontend" {
  bucket = aws_s3_bucket.pollibi_frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "pollibi_frontend" {
  depends_on = [
    aws_s3_bucket_ownership_controls.pollibi_frontend,
    aws_s3_bucket_public_access_block.pollibi_frontend
  ]
  bucket = aws_s3_bucket.pollibi_frontend.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "pollibi_frontend" {
  bucket = aws_s3_bucket.pollibi_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.pollibi_frontend.arn}/*"
      }
    ]
  })
}

# IAM Role for Lambda
resource "aws_iam_role" "pollibi_lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.pollibi_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "pollibi_lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.pollibi_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech",
          "polly:DescribeVoices"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.pollibi_audio.arn}/*"
      }
    ]
  })
}

# Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/templates/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "pollibi_tts" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-tts-function"
  role          = aws_iam_role.pollibi_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 128

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.pollibi_audio.bucket
    }
  }

  tags = {
    Name        = "${var.project_name}-tts-function"
    Environment = var.environment
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "pollibi_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "POLLIBI Text-to-Speech API"

  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "pollibi_stage" {
  api_id      = aws_apigatewayv2_api.pollibi_api.id
  name        = var.environment
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "pollibi_integration" {
  api_id             = aws_apigatewayv2_api.pollibi_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.pollibi_tts.invoke_arn
}

resource "aws_apigatewayv2_route" "pollibi_route" {
  api_id    = aws_apigatewayv2_api.pollibi_api.id
  route_key = "POST /synthesize"
  target    = "integrations/${aws_apigatewayv2_integration.pollibi_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pollibi_tts.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.pollibi_api.execution_arn}/*/*/synthesize"
}

# Upload frontend files
resource "aws_s3_object" "frontend_index" {
  bucket       = aws_s3_bucket.pollibi_frontend.id
  key          = "index.html"
  source       = "${path.module}/frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/frontend/index.html")
}

resource "aws_s3_object" "frontend_css" {
  bucket       = aws_s3_bucket.pollibi_frontend.id
  key          = "style.css"
  source       = "${path.module}/frontend/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.module}/frontend/style.css")
}

resource "aws_s3_object" "frontend_js" {
  bucket       = aws_s3_bucket.pollibi_frontend.id
  key          = "script.js"
  source       = "${path.module}/frontend/script.js"
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/frontend/script.js")
}
