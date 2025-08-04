# AWS Windows Secret Rotation Module

## Overview

The **AWS Windows Secret Rotation Module** is a Terraform module that provides automated credential rotation for Windows Server instances using AWS Secrets Manager, Lambda, and Systems Manager (SSM). This module enables secure, automated management of Windows administrator credentials across multiple EC2 instances, ensuring compliance with security best practices while minimizing operational overhead.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [Configuration Examples](#configuration-examples)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Features

- **Automated Credential Rotation**: Configurable rotation schedule with default 30-day intervals
- **Multi-Instance Support**: Manage credentials across multiple Windows EC2 instances with a single secret
- **Secure Storage**: Integration with AWS Secrets Manager with optional KMS encryption
- **Zero Downtime**: Seamless credential updates without service interruption
- **Audit Trail**: Comprehensive CloudWatch logging for all rotation activities
- **Region-Agnostic**: Deploy in any AWS region with full support
- **Idempotent Operations**: Safe to run multiple times without side effects

## Architecture

The module implements a serverless architecture for credential rotation:

```
┌─────────────────────────┐
│   AWS Secrets Manager   │
│  (Stores Credentials)   │
└───────────┬─────────────┘
            │ Triggers rotation
            ▼
┌─────────────────────────┐
│    Lambda Function      │
│  (Python 3.12 Runtime)  │
└───────────┬─────────────┘
            │ Updates via SSM
            ▼
┌─────────────────────────┐
│   Windows EC2 Instances │
│   (Target Servers)      │
└─────────────────────────┘
```

### Component Details

1. **Secrets Manager**: Stores encrypted Windows credentials and manages rotation lifecycle
2. **Lambda Function**: Executes the four-phase rotation process (create, set, test, finish)
3. **Systems Manager**: Provides secure command execution on Windows instances
4. **CloudWatch Logs**: Captures detailed logs for monitoring and troubleshooting

## Prerequisites

### AWS Account Requirements

- AWS account with appropriate permissions
- IAM permissions to create:
  - Secrets Manager secrets
  - Lambda functions and execution roles
  - CloudWatch log groups
  - IAM roles and policies

### Windows Instance Requirements

- Windows Server 2016 or later
- SSM Agent installed and running (pre-installed on AWS Windows AMIs)
- EC2 instance role with the following permissions:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:*",
          "ec2messages:*"
        ],
        "Resource": "*"
      }
    ]
  }
  ```
- Network connectivity to AWS endpoints (Secrets Manager, SSM, Lambda)

### Local Development Requirements

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Git for version control

## Installation

### Via Git Clone

```bash
git clone https://github.com/muzammilkazmi86/aws_winrotate_module.git
cd aws_winrotate_module
```

### As a Terraform Module

```hcl
module "windows_secret_rotation" {
  source = "github.com/muzammilkazmi86/aws_winrotate_module"
  
  secret_name          = "my-windows-admin-secret"
  region              = "us-east-1"
  windows_instance_ids = ["i-1234567890abcdef0"]
}
```

## Usage

### Basic Implementation

1. Create a `main.tf` file:

```hcl
provider "aws" {
  region = var.aws_region
}

module "windows_rotation" {
  source = "./modules/windows-secret-rotation"
  
  secret_name          = "${var.environment}-windows-admin"
  region              = var.aws_region
  windows_instance_ids = var.instance_ids
  rotation_days       = 30
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

2. Create a `terraform.tfvars` file:

```hcl
aws_region   = "us-east-1"
environment  = "production"
instance_ids = ["i-1234567890abcdef0", "i-0987654321fedcba0"]
```

3. Deploy the infrastructure:

```bash
terraform init
terraform plan
terraform apply
```

## Module Inputs

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `secret_name` | string | Name of the secret in AWS Secrets Manager | - | yes |
| `region` | string | AWS region where resources will be created | - | yes |
| `windows_instance_ids` | list(string) | List of Windows EC2 instance IDs | - | yes |
| `rotation_days` | number | Number of days between automatic rotations | 30 | no |
| `enable_rotation` | bool | Enable automatic rotation | true | no |
| `kms_key_id` | string | KMS key ID for secret encryption | null | no |
| `tags` | map(string) | Tags to apply to all resources | {} | no |

## Module Outputs

| Output | Type | Description |
|--------|------|-------------|
| `secret_arn` | string | ARN of the created secret |
| `secret_name` | string | Name of the created secret |
| `lambda_function_arn` | string | ARN of the rotation Lambda function |
| `lambda_function_name` | string | Name of the rotation Lambda function |
| `rotation_enabled` | bool | Whether rotation is enabled |

## Configuration Examples

### Production Environment with KMS Encryption

```hcl
module "prod_windows_rotation" {
  source = "github.com/muzammilkazmi86/aws_winrotate_module"
  
  secret_name          = "prod-windows-credentials"
  region              = "us-east-1"
  windows_instance_ids = ["i-prod001", "i-prod002", "i-prod003"]
  rotation_days       = 7
  kms_key_id         = aws_kms_key.prod.arn
  
  tags = {
    Environment = "production"
    Compliance  = "SOC2"
    CostCenter  = "IT-Security"
  }
}
```

### Development Environment

```hcl
module "dev_windows_rotation" {
  source = "github.com/muzammilkazmi86/aws_winrotate_module"
  
  secret_name          = "dev-windows-credentials"
  region              = "us-west-2"
  windows_instance_ids = ["i-dev001"]
  rotation_days       = 90
  enable_rotation     = false  # Manual rotation only
  
  tags = {
    Environment = "development"
  }
}
```

## Security Considerations

### Encryption

- Secrets are encrypted at rest using AWS Secrets Manager default encryption
- Optional KMS encryption provides additional control over encryption keys
- All API calls use TLS encryption in transit

### Access Control

- Lambda function uses least-privilege IAM policies
- Secrets access is restricted to the rotation function and authorized principals
- CloudWatch logs are retained for audit purposes

### Best Practices

1. Enable automatic rotation with appropriate intervals
2. Use KMS encryption for production environments
3. Regularly review CloudWatch logs for anomalies
4. Implement alerting for rotation failures
5. Test rotation in non-production environments first

## Troubleshooting

### Common Issues

#### Rotation Fails with Timeout

**Symptoms**: Lambda function times out during rotation

**Solutions**:
- Verify SSM Agent is running on target instances
- Check security groups allow SSM connectivity
- Increase Lambda timeout if needed

#### Permission Denied Errors

**Symptoms**: Rotation fails with access denied errors

**Solutions**:
- Verify EC2 instance role has SSM permissions
- Check Lambda execution role has required permissions
- Ensure KMS key policy allows Lambda function access

#### Instance Not Found

**Symptoms**: Rotation fails with instance not found error

**Solutions**:
- Verify instance IDs are correct
- Ensure instances are in the specified region
- Check instances are in running state

### Debug Commands

```bash
# Check SSM Agent status
aws ssm describe-instance-information --region us-east-1

# View Lambda logs
aws logs tail /aws/lambda/<function-name> --follow

# Manually trigger rotation
aws secretsmanager rotate-secret --secret-id <secret-name>

# Get current secret value
aws secretsmanager get-secret-value --secret-id <secret-name>
```

## Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Terraform best practices
- Include unit tests for new features
- Update documentation as needed
- Ensure backward compatibility

## Support

### Community Support

- Open an issue for bug reports or feature requests
- Check existing issues before creating new ones
- Provide detailed information for troubleshooting

## Acknowledgments

- Syed Kazmi

---

**Note**: This module is not officially supported by AWS. Use at your own discretion and always test in non-production environments first.
