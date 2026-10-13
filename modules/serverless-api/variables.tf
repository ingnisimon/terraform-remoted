variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}

variable "app_name" {
  description = "The base name of the application"
  type        = string
  default     = "visitor-counter"
}

variable "db_read_capacity" {
  description = "DynamoDB read capacity units"
  type        = number
}

variable "db_write_capacity" {
  description = "DynamoDB write capacity units"
  type        = number
}
