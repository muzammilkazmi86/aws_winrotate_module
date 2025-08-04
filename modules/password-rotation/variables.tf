variable "instances" {
  description = "List of instance configurations with instance_id, secret_name, and windows_username"
  type = list(object({
    instance_id     = string
    secret_name     = string
    windows_username = string
  }))
}

variable "lambda_timeout" {
  type        = number
  default     = 60
  description = "Timeout in seconds for the Lambda function"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Log retention in days for CloudWatch"
}

variable "rotation_schedule" {
  type        = number
  default     = 30
  description = "Days after which password is automatically rotated"
}

variable "recovery_window_days" {
  type        = number
  default     = 0
  description = "Recovery window in days for Secrets Manager secrets"
}

variable "log_level" {
  type        = string
  default     = "INFO"
  description = "Log level for Lambda"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
