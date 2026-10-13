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
