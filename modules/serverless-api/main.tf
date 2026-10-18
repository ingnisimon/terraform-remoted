# 0. DynamoDB table declaration
resource "aws_dynamodb_table" "app_table" {
  name           = "${var.environment}-${var.app_name}-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.db_read_capacity
  write_capacity = var.db_write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}
# 1. IAM Execution Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.environment}-${var.app_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. IAM Policy to access DynamoDB and CloudWatch Logs
resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "${var.environment}-dynamodb-access"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.app_table.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 3. Zip the Python code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/source_code"
  output_path = "${path.module}/lambda.zip"
}

# 4. Provision the Lambda Function
resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-${var.app_name}-function"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app_place_holder.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.app_table.name
      ENVIRONMENT = var.environment
    }
  }
}
# 5. API Gateway HTTP API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.environment}-${var.app_name}-api"
  protocol_type = "HTTP"
}

# 6. API Gateway Stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.environment
  auto_deploy = true
}

# 7. API Gateway Integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

# 8. API Gateway Route
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 9. Lambda Permission to allow API Gateway invocation
resource "aws_lambda_permission" "api_gw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
output "api_endpoint" {
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
  description = "The live URL of the API Gateway stage."
}
