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
