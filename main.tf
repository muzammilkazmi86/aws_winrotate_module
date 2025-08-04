module "windows_password_rotation" {
  source = "./modules/password-rotation"

  instances = [
    {
      instance_id      = "i-0591a47393bab6406"
      secret_name      = "WinPassword1"
      windows_username = "Administrator"
    },
    {
      instance_id      = "i-02bedb01eb219a48d"
      secret_name      = "WinPassword2"
      windows_username = "Admininstrator"
    }
  ]

  lambda_timeout         = 60
  log_retention_days     = 14
  rotation_schedule      = 30
  recovery_window_days   = 0
  log_level              = "INFO"
  tags = {
    Environment = "prod"
    Team        = "security"
  }
}
